require 'nokogiri'
require 'open-uri'

require 'rubygems'
require 'neography'

require 'redis'
require 'cgi'

# start n=node(50000) match n-[:LINKS_TO]->m return ID(n),n.title,"LINKS_TO",ID(m),m.title;

#@redis = Redis.new(:host => "46.137.39.99", :port => 6379)
#@neo4j = Neography::Rest.new({:server => @redis.get("neo4jIP"), :port => @redis.get("neo4jPort")})

#@urlWiki = @redis.get("wikipediaUrl")
#@rTitleList = @redis.get("redisKeyForWikipediaTitles")
#@rTitleListFAIL = @redis.get("redisKeyForWikipediaTitles.FAIL")

#@rCypherQueryList = @redis.get("cypherQueries")

#@rTitleList = @redis.get("redisTemp")
#@rTitleListFAIL = @redis.get("redisTempFailure")


@deleteKeys = ["Spezial:", "Diskussion:", "Benutzer:", "Wikipedia:", 
	"Wikipedia_Diskussion:", "Datei:", "Datei_Diskussion:", 
	"MediaWiki:", "MediaWiki_Diskussion:", "Vorlage:", "Vorlage_Diskussion:", 
	"Hilfe:", "Hilfe_Diskussion:", "Kategorie:", 
	"Kategorie_Diskussion:", "Portal:", "Portal_Diskussion:", 
	"Medium:", "TimedText:", "TimedText_Diskussion:"]

def scrapeWikiPage(urlWiki, urlTitle)

        doc = Nokogiri::HTML(open(urlWiki+urlTitle+"?redirect=no"))
        title = doc.css('title').map { |t| t.text.gsub(" – Wikipedia", "") }[0] # :(

        article = "<a><at>#{CGI::escape(title)}</at><au>#{urlWiki+urlTitle}</au>"
		
        links = doc.css('div#mw-content-text a').map { |link|
                ( link['href'].byteslice(0,6)=="/wiki/" #keine steuerungsseiten
                ) ? {"url" => (urlWiki.gsub("/wiki/", "") + "#{(link['href'].index('#')!=nil)?link['href'][0..(link['href'].index('#')-1)]:link['href']}"), "title" => CGI::escape(((link['title']!=nil)?link['title']:((link.text!=nil)?link.text:"unknown")))} : nil}
        links.delete(nil) 
			
		#url-duplikate entfernen
		links = links.inject({}) do |r, h| 
		  (r[h["url"]] ||= {}).merge!(h){ |key, old, new| old || new }
		  r
		end.values	
		#
		
		links.delete_if{ |link| remove_entry = false; @deleteKeys.each { |e| if link["url"].include? e;  remove_entry = true; break; end }; remove_entry }
		
		if doc.css('div.redirectMsg').length != 0
			article +="<afw>true</afw>"
		else
			article +="<afw>false</afw>"
		end
		
		article += "<als>"
		links.each do |link|
			article += "<l><lt>#{link["title"]}</lt><lu>#{link["url"]}</lu></l>"
		end
		article += "</als></a>"

		puts article
		#@redis.LPUSH(@rCypherQueryList, article)
		puts "article added to redis: #{title}"

end


def saveError(source, e)
        File.open("scrap2redis_xml_err.log", 'a') { |file|
                file.write("Error at:\n#{source}\n\n")
                file.write("Time:\n#{Time.now}\n\n")
                file.write("Reason:\n#{e.message}\n---\n")
                e.backtrace.each { |line| file.write("#{line}\n") }
                file.write("\n------------------------------------------------\n\n")
        }
        puts "\n---\nThe script caused an error! Please check the log file!\n---\n"
end

scrapeWikiPage("http://de.wikipedia.org/wiki/", "!")

# rc = 0

# loop do
        # while title = @redis.RPOP(@rTitleList)
                # begin
                        # scrapeWikiPage(@urlWiki, title)
                        # rc = 0
                # rescue => e
                        # @redis.LPUSH(@rTitleListFAIL, title)
                        # saveError(@urlWiki+title, e)
                        # e.backtrace.each { |line| puts line }
                # end
        # end

        # if(rc==0)
          # print "waiting for new titles in redis list ..."
        # else
          # if(rc%1000==0)
            # print "."
          # end
        # end

        # rc+=1
# end