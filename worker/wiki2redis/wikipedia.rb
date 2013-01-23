#deprecated, use instead titles2redis.rb

require 'rubygems'
require 'net/http'
require 'uri'
require 'json'
require 'cgi'
require "redis"

@domain = "http://de.wikipedia.org"

beginning = Time.now

r = Redis.new(:host => "79.125.75.198", :port => 6379)

start = "!"

while start do
        links = []
        uri = URI.parse("http://de.wikipedia.org/w/api.php?format=json&action=query&generator=allpages&gaplimit=500&gapfrom=#{start}&prop=info&inprop=url")

        response = Net::HTTP.get_response uri
        t = JSON.parse(response.body)

        (t["query"]["pages"]).each do |e|
                links << CGI.escape(e[1]["fullurl"].gsub(@domain, ""))
                end

        r.LPUSH("wikipedia_list6", links)

                if t["query-continue"] && t["query-continue"]["allpages"] && t["query-continue"]["allpages"]["gapcontinue"]
                        start = t["query-continue"]["allpages"]["gapcontinue"]
                        print start + " - " + URI.encode(start) + " - " + CGI.escape(start) + "\n"
                        start = CGI.escape(start)
                else
                        print "stopping at '" + start + "'"
                        start = nil
                end
end

puts "Time elapsed #{Time.now - beginning} seconds"
