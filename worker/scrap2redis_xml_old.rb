require 'nokogiri'
require 'open-uri'

require 'rubygems'
require 'neography'

require 'redis'
require 'cgi'

@redis = Redis.new(:host => "46.137.39.99", :port => 6379)
@neo4j = Neography::Rest.new({:server => @redis.get("neo4jIP"), :port => @redis.get("neo4jPort")})

@urlWiki = @redis.get("wikipediaUrl")
#@rTitleList = @redis.get("redisKeyForWikipediaTitles")
#@rTitleListFAIL = @redis.get("redisKeyForWikipediaTitles.FAIL")

@rCypherQueryList = @redis.get("cypherQueries")

@rTitleList = @redis.get("redisTemp")
@rTitleListFAIL = @redis.get("redisTempFailure")


def scrapeWikiPage(urlWiki, urlTitle)

        doc = Nokogiri::HTML(open(urlWiki+urlTitle+"?redirect=no"))
        title = doc.css('title').map { |t| t.text.gsub(" – Wikipedia", "") }[0] # :(

        article = "<a><at>#{CGI::escape(title)}</at><au>#{urlWiki+urlTitle}</au>"
		
        links = doc.css('div#mw-content-text a').map { |link|
                (( link['href'].byteslice(0,6)=="/wiki/" && link['href'].index(':') == nil) #keine steuerungsseiten # v- Sprungmarken entfernen #xyz
                ) ? {"url" => (urlWiki.gsub("/wiki/", "") + link['href']), "title" => CGI::escape("#{x.index('#')?x[0..(-1*(x.length-(x.index('#'))))-1]:x}")} : nil}
        links.delete(nil) 
			
		#url-duplikate entfernen
		links = links.inject({}) do |r, h| 
		  (r[h["url"]] ||= {}).merge!(h){ |key, old, new| old || new }
		  r
		end.values	
		#
		
		if doc.css('div.redirectMsg').length != 0
			article += "<als>"
			links.each do |link|
				article += "<l><lt>#{link["title"]}</lt><lu>#{link["url"]}</lu></l>"
			end
			article += "</als></a>"
		else
			article += "<als>"
			links.each do |link|
				article += "<l><lt>#{link["title"]}</lt><lu>#{link["url"]}</lu></l>"
			end
			article += "</als></a>"

		end

		@redis.LPUSH(@rCypherQueryList, article)
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