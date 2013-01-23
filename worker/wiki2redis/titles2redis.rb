#download all titles from wikipedia in a file and push them on redis

require 'rubygems'
require 'redis'
require 'cgi'

r = Redis.new(:host => "79.125.75.198", :port => 6379)

redis_listname = r.get("redisKeyForWikipediaTitles") #"wikiTitles"

r.del(redis_listname)

file = File.open(ARGV[0])
titles = []

puts 'script running...'
puts 'moving wikipedia titles to redis key #{redis_listname}'

file.each_with_index do |line, index|
        next if index == 0
        titles <<  CGI.escape(line.chop)

        if index % 10000 == 0
                r.LPUSH(redis_listname, titles)
                titles.clear
        end
end

r.LPUSH(redis_listname, titles)

puts 'script stopped'

