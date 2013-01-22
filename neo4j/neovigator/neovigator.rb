require 'rubygems'
require 'neography'
require 'sinatra/base'
require 'uri'
require 'cgi'

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
                          {"type"=> "contains link to", "direction" => "out"},
                          depth=10, # Suchtiefe
                          algorithm="shortestPath") # "allPaths", "allSimplePaths", "shortestPath", "allPaths", "allSimplePaths", "shortestPath"
  
    puts "Number of paths found #{paths.size}"
    
    paths.each do |p|
      p["x"] = p["nodes"].collect { |node|
        neo.get_node_properties(node).merge({"neoid" => node_id(node)}) }
    end
  end

  def print_paths(sNode, dNode, max_one)
    pathstring = ""
    ssteps = ""
    paths = find_paths(sNode, dNode)
    
    if(max_one)
      #paths = {0  => paths[0]}
    end

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

  def get_node_by_title(title)
    if(title!=nil)
      cypher_query = " START n=node(*)" 
      cypher_query << " WHERE n.title = "
      cypher_query << "'" + title + "'"
      cypher_query << " RETURN n"
      puts cypher_query
      result = neo.execute_query(cypher_query)

      result = (result!=nil&&result["data"]!=nil&&result["data"][0])? result["data"][0][0] : nil
    else
      result = nil
    end

    return result
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
         outgoing["Outgoing:#{rel["type"]}"] << {:values => nodes[rel["end"]].merge({:id => node_id(rel["end"]) }) }
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

  get '/sinatra/:id/:subid' do
    "Hello World! Sinatra noticed your ID#{params[:id]}/#{params[:subid]}"  
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
    @pathstring = (@snode!=nil&&@dnode!=nil)?print_paths(@snode,@dnode, true):"One of the articles wasn't found"
    @pathstring = (@stitle!=nil&&@dtitle!=nil)?@pathstring: ""
    @stitle = (@stitle!=nil)?CGI::unescape(@stitle):""
    @dtitle = (@dtitle!=nil)?CGI::unescape(@dtitle):""

    haml :pathfinder, :layout => false
  end


  get '/statistics/top20/mostlinked' do
    content_type :json
    "[['Artikel1', '<a href=\"url1\">Article11</a>', 'linkedNumber'],['Artikel2', '<a href=\"url2\">Article2</a>', 'linkedNumber'],['Artikel3', '<a href=\"url3\">Article3</a>', 'linkedNumber']]"
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
