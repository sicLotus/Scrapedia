require 'rubygems'
require 'redis'
require 'cgi'

r = Redis.new(:host => "46.137.39.99", :port => 6379)

beginning = Time.now

redis_listname = r.get("redisTemp") #"tmp"

puts "delete old #{redis_listname}"
r.del(redis_listname)

file = File.open(ARGV[0])
titles = []

puts "moving wikipedia titles to redis key #{redis_listname}"

file.each_with_index do |line, index|
        next if index == 0
        titles <<  CGI.escape(line.chop)

        if index % 10000 == 0
                r.LPUSH(redis_listname, titles)
                titles.clear
        end
end

r.LPUSH(redis_listname, titles)

puts "script stopped.\nTime elapsed #{Time.now - beginning} seconds"
