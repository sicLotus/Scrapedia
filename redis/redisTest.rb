#simple testscript for xml data in redis

require 'rubygems'
require 'redis'
require 'cgi'

@redis = Redis.new(:host => "46.137.39.99", :port => 6379)
@rCypherQueryList = @redis.get("cypherQueries")

@rTitleList = @redis.get("redisTemp")
@rTitleListFAIL = @redis.get("redisTempFailure")

for i in 0..100
  @redis.LPUSH(@rCypherQueryList, "<a><at>#{CGI::escape("atitle#{i}")}</at><au>#{CGI::escape("aurl{i}")}</au><als><l><lt>#{CGI::escape("ltitle#{i}_1")}</lt><lu>#{CGI::escape("lurl#{i}_1")}</lu></l><l><lt>#{CGI::escape("ltitle#{i}_2")}</lt><lu>#{CGI::escape("lurl#{i}_2")}</lu></l><l><lt>#{CGI::escape("ltitle{i}_3")}</lt><lu>#{CGI::escape("lurl{i}_4")}</lu></l></als></a>")
end

# <a>
  # <at>atitle</at>
  # <au>url</au>
  # <als>
    # <l>
      # <lt>ltitle</lt>
      # <lu>lurl</lu>
    # </l>
    # <l>
      # <lt>ltitle</lt>
      # <lu>lurl</lu>
    # </l>
    # <l>
      # <lt>ltitle</lt>
      # <lu>lurl</lu>
    # </l>
  # </als>
# </a>
