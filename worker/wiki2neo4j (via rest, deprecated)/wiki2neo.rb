#deprecated

require 'nokogiri'
require 'open-uri'

require 'rubygems'
require 'neography'

require 'redis'
require 'cgi'

@redis = Redis.new(:host => "79.125.75.198", :port => 6379)
@neo4j = Neography::Rest.new({:server => @redis.get("neo4jIP"), :port => @redis.get("neo4jPort")})

@urlWiki = @redis.get("wikipediaUrl")
@rTitleList = @redis.get("redisKeyForWikipediaTitles")

@rTitleListFAIL = @redis.get("redisKeyForWikipediaTitles.FAIL")

if File.exist?("wiki2neo_err.log") 
	File.delete("wiki2neo_err.log")
end

def createRemoteArticle(link)
        @neo4j.create_unique_node('urls', 'url', link["url"], {"url" => link["url"], "title" => link["text"]})
end

def createFinalArticle(link)
        a = @neo4j.create_unique_node('urls', 'url', link["url"], {"url" => link["url"], "title" => link["text"]})
        id = a["self"].split("/").last
        new_title = link["text"]

		#TODO- Benjamin: sicher gegen SQL-Injection machen
        cypher_query = " START n=node("+id+")"
        cypher_query << " SET n.title ="
        cypher_query << " '" + new_title +"'"
        cypher_query << " RETURN n"
        @neo4j.execute_query(cypher_query)

        return a
end

def linkArticles(node1, node2)
  return @neo4j.create_unique_relationship("lids", "lid", "#{node1["self"].split("/").last}-#{node2["self"].split("/").last}", "contains link to", node1, node2)
end

def redirectArticles(node1, node2)
  return @neo4j.create_unique_relationship("rids", "rid", "#{node1["self"].split("/").last}-#{node2["self"].split("/").last}", "redirects to", node1, node2)
end

def scrapeWikiPage(urlWiki, urlTitle)


        doc = Nokogiri::HTML(open(urlWiki+urlTitle+"?redirect=no"))
        title = doc.css('title').map { |t| t.text.gsub(" – Wikipedia", "") }[0] # :(

        article = createFinalArticle({"url" => urlWiki+urlTitle, "text" => CGI::escape(title)})

        links = doc.css('div#mw-content-text a').map { |link|
                (( link['href'].byteslice(0,6)=="/wiki/" && link['href'].index(':') == nil) #keine steuerungsseiten
                ) ? {"url" => (urlWiki.gsub("/wiki/", "") + link['href']), "text" => CGI::escape(link.text)} : nil}
        links.delete(nil) #TODO: url-dublicate schon vorher ausfiltern -> spart Anfragen

		puts urlWiki + urlTitle + " (#{article["self"].split("/").last})"
        puts "------------------------------------------------"
		
		if doc.css('div.redirectMsg').length != 0
			links.each do |link|
					rarticle = createRemoteArticle(link)
					print "create: " + rarticle["self"].split("/").last + " | "
					rship = redirectArticles(article, rarticle)
					puts "redirect: " + article["self"].split("/").last + " >> ["+ rship["data"]["rid"] +"] >> "+ rarticle["self"].split("/").last
			end
		else
			links.each do |link|
					rarticle = createRemoteArticle(link)
					print "create: " + rarticle["self"].split("/").last + " | "
					rship = linkArticles(article, rarticle)
					puts "link: " + article["self"].split("/").last + " >> ["+ rship["data"]["lid"] +"] >> "+ rarticle["self"].split("/").last
			end
		end
        puts "------------------------------------------------"
        puts "TOTAL:"
        puts "  -> Article##{article["self"].split("/").last} links(IN:#{countLinks(article,"in")}/OUT:#{countLinks(article,"out")})"
		puts "------------------------------------------------"
end

def countLinks(article, dir)
        r = @neo4j.get_node_relationships(article["self"].split("/").last, dir)
        return (r != nil)? r.size : 0
end

def saveError(source, e)
        File.open("wiki2neo_err.log", 'a') { |file|
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

