require 'rubygems'
require 'redis'

@redis = Redis.new

hash = Hash[*File.read('redis.properties').split(/=|\n/)]

hash.each_pair do |k,v|
  @redis.set(k,v)
end
