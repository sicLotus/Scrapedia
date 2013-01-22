require 'nokogiri'
require 'open-uri'

require 'rubygems'
require 'neography'

require 'redis'
require 'cgi'

# WICHTIG ZUR INITIALISIERUNG
# start n=node(0) create unique n-[:wiki]->(m {url:"http://de.wikipedia.org/wiki/", title:"Wikipedia"}) return m;
#

# COMMANDS
# start n=node(1) create unique n-[:owns]->(m {url:"http://de.wikipedia.org/wiki/X", title:"X"}) return m;
# start n=node(X) MATCH n-->m return m;
# start n=node(X) match n-[r?]->() delete n, r;
#

@wiki_id = 1

@redis = Redis.new(:host => "79.125.75.198", :port => 6379)
@neo4j = Neography::Rest.new({:server => @redis.get("neo4jIP"), :port => @redis.get("neo4jPort")})
#@neo4j = Neography::Rest.new({:port => 3306})

@urlWiki = @redis.get("wikipediaUrl")
@rTitleList = @redis.get("redisKeyForWikipediaTitles")
@rTitleListFAIL = @redis.get("redisKeyForWikipediaTitles.FAIL")

# @rTitleList = @redis.get("redisTemp")
# @rTitleListFAIL = @redis.get("redisTempFailure")

# if File.exist?("wiki2neo_err.log") 
	# File.delete("wiki2neo_err.log")
# end


def createFinalArticle(link)
		cypher_query = "start w=node(#{@wiki_id}) create unique w-[:owns]->(n {url:'#{link["url"]}'}) set n.title = '#{link["text"]}' return n;"
		a = @neo4j.execute_query(cypher_query)
		
		return a["data"][0][0]
end

def linkAllRemoteArticles(article, links, relationship_typ)
	astring = " create unique "
	cstring = " create unique "
	sstring = " set "
	wstring = " with n, "
	
	i=0;
	max=200;
	
	links.each do |link|
			
			if (i%max==0 && i!=0)
				cypher_query = "start w=node(#{@wiki_id}), n=node(#{article["self"].split("/").last})" + cstring.chop.chop + sstring.chop.chop + wstring.chop.chop + astring.chop.chop
				@neo4j.execute_query(cypher_query)
				
				astring = " create unique "
				cstring = " create unique "
				sstring = " set "
				wstring = " with n, "
				
				print "."
				#puts "\n" + cypher_query
			end
	
			cstring += "w-[:owns]->(n#{i} {url: '#{link["url"]}'}), "
			astring += "n-[:#{relationship_typ}]->(n#{i}), "
			sstring += "n#{i}.title = coalesce(n#{i}.title?, '#{link["text"]}'), "

			wstring +="n#{i}, "
			i=i+1
	end

	cypher_query = "start w=node(#{@wiki_id}), n=node(#{article["self"].split("/").last})" + cstring.chop.chop + sstring.chop.chop + wstring.chop.chop + astring.chop.chop
	@neo4j.execute_query(cypher_query)
end

def scrapeWikiPage(urlWiki, urlTitle)


        doc = Nokogiri::HTML(open(urlWiki+urlTitle+"?redirect=no"))
        title = doc.css('title').map { |t| t.text.gsub(" – Wikipedia", "") }[0] # :(

        puts "----------------------------------------------------------"
		print "create final article: #{title} ..."
        article = createFinalArticle({"url" => urlWiki+urlTitle, "text" => CGI::escape(title)})
		print " (#{article["self"].split("/").last}) ... done\n"
		
        links = doc.css('div#mw-content-text a').map { |link|
                (( link['href'].byteslice(0,6)=="/wiki/" && link['href'].index(':') == nil) #keine steuerungsseiten
                ) ? {"url" => (urlWiki.gsub("/wiki/", "") + link['href']), "text" => CGI::escape(link.text)} : nil}
        links.delete(nil) 
			
		#url-duplikate entfernen
		links = links.inject({}) do |r, h| 
		  (r[h["url"]] ||= {}).merge!(h){ |key, old, new| old || new }
		  r
		end.values	
		#
		
		if doc.css('div.redirectMsg').length != 0
			print "create redirections ..."
			linkAllRemoteArticles(article, links, "contains_link_to")
			linkAllRemoteArticles(article, links, "is_redirection_of")
			print " done\n"
		else
			print "create links and relationships ..."
			linkAllRemoteArticles(article, links, "contains_link_to")
			print " done\n"
		end
        puts "----------------------------------------------------------"
        puts "TOTAL:"
        puts "  -> Article##{article["self"].split("/").last} links(IN:#{countLinks(article,"in")}/OUT:#{countLinks(article,"out")})"
		puts "----------------------------------------------------------"
end

def countLinks(article, dir)
        r = @neo4j.get_node_relationships(article["self"].split("/").last, dir)
        return (r != nil)? r.size : 0
end

def saveError(source, e)
        File.open("light_wiki2neo_err.log", 'a') { |file|
                file.write("Error at:\n#{source}\n\n")
                file.write("Time:\n#{Time.now}\n\n")
                file.write("Reason:\n#{e.message}\n---\n")
                e.backtrace.each { |line| file.write("#{line}\n") }
                file.write("\n------------------------------------------------\n\n")
        }
        puts "\n---\nThe script caused an error! Please check the log file!\n---\n"
end


rc = 0

loop do
        while title = @redis.RPOP(@rTitleList)
                begin
                        scrapeWikiPage(@urlWiki, title)
                        rc = 0
                rescue => e
                        @redis.LPUSH(@rTitleListFAIL, title)
                        saveError(@urlWiki+title, e)
                        e.backtrace.each { |line| puts line }
                end
        end

        if(rc==0)
          print "waiting for new titles in redis list ..."
        else
          if(rc%1000==0)
            print "."
          end
        end

        rc+=1
end