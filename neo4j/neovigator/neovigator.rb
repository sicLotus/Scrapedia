require 'rubygems'
require 'neography'
require 'sinatra/base'
require 'uri'
require 'cgi'
require 'net/http'

# Lengthen timeout in Net::HTTP
module Net
    class HTTP
        alias old_initialize initialize

        def initialize(*args)
            old_initialize(*args)
            @read_timeout = 120     # 2min
        end
    end
end

class Neovigator < Sinatra::Application
  set :haml, :format => :html5 
  set :app_file, __FILE__

  configure :test do
    require 'net-http-spy'
    Net::HTTP.http_logger_options = {:verbose => true} 
  end

  helpers do
    def link_to(url, text=url, opts={})
      attributes = ""
      opts.each { |key,value| attributes << key.to_s << "=\"" << value << "\" "}
      "<a href=\"#{url}\" #{attributes}>#{text}</a>"
    end

    def neo
      @neo = Neography::Rest.new("http://localhost:3306")
    end
  end

  def numeric?(object)
    true if Float(object) rescue false
  end

  def get_size(object)
    return (object!=nil)?object.size : 0
  end

  def create_graph
    graph_exists = neo.get_node_properties(1)
    return if graph_exists && graph_exists['name']

    puts "Graph DB is empty"
  end

  def neighbours
    {"order"         => "depth first",
     "uniqueness"    => "none",
     "return filter" => {"language" => "builtin", "name" => "all_but_start_node"},
     "depth"         => 1}
  end

  def node_id(node)
    case node
      when Hash
        node["self"].split('/').last
      when String
        node.split('/').last
      else
        node
    end
  end

  def find_paths(sNode, dNode)
    paths = neo.get_paths(sNode,
                         dNode,
                          {"type"=> "LINKS_TO", "direction" => "out"},
                          depth=10, # Suchtiefe
                          algorithm="shortestPath") # "allPaths", "allSimplePaths", "shortestPath", "allPaths", "allSimplePaths", "shortestPath"
  
    puts " found: #{paths.size}"
    
    paths.each do |p|
      p["x"] = p["nodes"].collect { |node|
        neo.get_node_properties(node).merge({"neoid" => node_id(node)}) }
    end
  end

  def print_paths(sNode, dNode)
    pathstring = ""
    ssteps = ""
    paths = find_paths(sNode, dNode)

    paths.each do |path|
      pathstring << "<ol>"
      path["x"].each do |a|
        print " => " + CGI::unescape(a["title"])
        pathstring << "<li><a href='/neovigator?neoid=#{a["neoid"]}' target='_blank'><img src='/img/neo4j_logo.png'/></a> " 
        pathstring << "<a href='#{a["url"]}' target='_blank'>#{CGI::unescape(a["title"])}</a></li>" 
      end
      print "\n"
      pathstring << "</ol>"
      
      ssteps = "Number of steps to destination: #{(path["x"].size - 1)}<br/>\n"
    end

    scount = "Number of shortest paths found: #{get_size(paths)}<br/>\n"
    return (pathstring!="") ? scount + ssteps + pathstring : "no path found"

  end

  def json_paths(sNode, dNode)
    pathstring = "["
    paths = find_paths(sNode, dNode)

    paths.each do |path|
      pathstring << "["
      path["x"].each do |a|
        pathstring << "{name:'#{a["title"]}', url:'#{a["url"]}'},"
      end
      pathstring = pathstring.chop
      pathstring << "],"
    end
    pathstring = pathstring.chop
    pathstring << "]"
    return (pathstring!="[]") ? pathstring : "['no path found']"

  end



  def get_node_by_title(title)
    if(title!=nil)
      cypher_query = " START n=node:pages" 
      cypher_query << "( url="
      cypher_query << " 'http://de.wikipedia.org/wiki/" + title + "')"
      cypher_query << " RETURN n"
      cypher_query << " LIMIT 1"      

      #puts cypher_query
      puts "article: #{title}"
      result = neo.execute_query(cypher_query)
      #puts result
      result = (result!=nil&&result["data"]!=nil&&result["data"][0])? result["data"][0][0] : nil
    else
      result = nil
    end

    return result
  end

  def countLinks(node, dir)
      r = neo.get_node_relationships(node["self"].split("/").last, dir)
      return (r != nil)? r.size : 0
  end


  def get_properties(node)
    properties = "<ul>"
    node["data"].each_pair do |key, value|
        properties << "<li><b>#{key}:</b> #{(key=="title"||key=="url")?CGI::unescape(value):value}</li>"
      end
    properties + "</ul>"
  end

  get '/resources/show' do
    content_type :json

    params[:id]=(params[:id]!="1")?params[:id]:"0";
    node = neo.get_node(params[:id]) 
    connections = neo.traverse(node, "fullpath", neighbours)
    incoming = Hash.new{|h, k| h[k] = []}
    outgoing = Hash.new{|h, k| h[k] = []}
    nodes = Hash.new
    attributes = Array.new

    connections.each do |c|
       c["nodes"].each do |n|
         nodes[n["self"]] = n["data"]
       end
       rel = c["relationships"][0]

       if rel["end"] == node["self"]
         incoming["Incoming:#{rel["type"]}"] << {:values => nodes[rel["start"]].merge({:id => node_id(rel["start"]) }) }
       else
         if rel["type"] != "INSTANCE_OF" &&  rel["type"] != "PAGES" 
           outgoing["Outgoing:#{rel["type"]}"] << {:values => nodes[rel["end"]].merge({:id => node_id(rel["end"]) }) }
         end
       end
    end

      incoming.merge(outgoing).each_pair do |key, value|
	foo = value.collect{|v| v[:values]}
	foo.each do |f|
		f["name"]=CGI::unescape(f["title"])
	end
        attributes << {:id => key.split(':').last, :name => key, :values => foo }
	
      end

   attributes = [{"name" => "No Relationships","name" => "No Relationships","values" => [{"id" => "#{params[:id]}","name" => "No Relationships "}]}] if attributes.empty?

    @node = {:details_html => "<h2>Neo ID: #{node_id(node)}</h2>\n<p class='summary'>\n#{get_properties(node)}</p>\n",
              :data => {:attributes => attributes, 
                        :name => CGI::unescape(node["data"]["title"]),
                        :id => node_id(node)}
            }
    
    @node.to_json

  end


  get '/neovigator' do
    create_graph
    @neoid = params["neoid"]

    haml :neovigator
  end

  get '/' do
    @pagetitle = "Home"
    haml :index, :layout => false 
  end

  get '/statistics' do
    @pagetitle = "Statistics"
    haml :statistics, :layout => false
  end

  get '/pathfinder' do

    @pagetitle = "PathFinder"

    @stitle = (params["stitle"]!=nil)?CGI::escape(params["stitle"]):nil
    @dtitle = (params["dtitle"]!=nil)?CGI::escape(params["dtitle"]):nil
    @snode = get_node_by_title(@stitle)
    @dnode = get_node_by_title(@dtitle)

    #puts @snode
    #puts @dnode
    if(@snode!=nil&&@dnode!=nil)
      print "finding incomming links..."
      scount = -1 #countLinks(@snode, "out")
      dcount = countLinks(@dnode, "in")
      print " done.\n"

      if (scount!=0&& dcount!=0)
        print "finding routes..."
        @pathstring = print_paths(@snode, @dnode)
        print " done.\n"
      else
        @pathstring = "Destination article has no incomming links! :("
      end
    else
      @pathstring = "One of the articles wasn't found!" 
    end

    #@pathstring = (@snode!=nil&&@dnode!=nil)?print_paths(@snode,@dnode):"One of the articles wasn't found"
    @pathstring = (@stitle!=nil&&@dtitle!=nil)?@pathstring: ""
    
    @stitle = (@stitle!=nil)?CGI::unescape(@stitle):""
    @dtitle = (@dtitle!=nil)?CGI::unescape(@dtitle):""
    puts "sending results...done.\n"
    haml :pathfinder, :layout => false
  end


  get '/pathfinder/json' do
    content_type :json

    @stitle = (params["stitle"]!=nil)?CGI::escape(params["stitle"]):nil
    @dtitle = (params["dtitle"]!=nil)?CGI::escape(params["dtitle"]):nil
    @snode = get_node_by_title(@stitle)
    @dnode = get_node_by_title(@dtitle)

    if(@snode!=nil&&@dnode!=nil)
      dcount = countLinks(@dnode, "in")

      if (dcount!=0)
        @pathstring = json_paths(@snode, @dnode)
      else
        @pathstring = "['Destination article has no incomming links! :(']"
      end
    else
      @pathstring = "['One of the articles was not found!']"
    end

    @pathstring = (@stitle!=nil&&@dtitle!=nil)?@pathstring: "[]"

    @stitle = (@stitle!=nil)?CGI::unescape(@stitle):""
    @dtitle = (@dtitle!=nil)?CGI::unescape(@dtitle):""
    
    "#{@pathstring}"
  end


  get '/statistics/top20/mostlinked' do
    content_type :json
    "[['Artikel1', '<a href=\"url1\">Article1</a>', 'linkedNumber'],['Artikel2', '<a href=\"url2\">Article2</a>', 'linkedNumber'],['Artikel3', '<a href=\"url3\">Article3</a>', 'linkedNumber']]"
  end

  get '/statistics/top20/mostlinks' do
    content_type :json
    "[['Artikel1', '<a href=\"url1\">Article1</a>', 'numberOfLinks'],['Artikel2', '<a href=\"url2\">Article2</a>', 'numberOfLinks'],['Artikel3', '<a href=\"url3\">Article3</a>', 'linkedNumber']]"
  end

  get '/statistics/list/nolinks' do
    content_type :html
    '<ul><li><a href="url">ArtikelName#1</a></li><li><a href="url">ArtikelName#2</a></li><li><a href="url">ArtikelName#3</a></li></ul>'
  end

  get '/statistics/list/unlinked' do
    content_type :html
    '<ul><li><a href="url">ArtikelName#1</a></li><li><a href="url">ArtikelName#2</a></li><li><a href="url">ArtikelName#3</a></li></ul>'
  end

end
