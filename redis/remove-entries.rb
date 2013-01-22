require 'rubygems'
require 'redis'

@redis = Redis.new



while True:
	key = @redis.rpop("wikiTitles")
	if key.eql? "<a><at>%21</at><au>http://de.wikipedia.org/wiki/%21</au><als><l><lt>Ausrufezeichen</lt><lu>http://de.wikipedia.org/wiki/Ausrufezeichen</lu></l></als></a>"
		break

@redis.rpush("wikiTitles", "<a><at>%21</at><au>http://de.wikipedia.org/wiki/%21</au><als><l><lt>Ausrufezeichen</lt><lu>http://de.wikipedia.org/wiki/Ausrufezeichen</lu></l></als></a>")
		
#for i in 0..344972
#  @redis.RPOP("wikiTitles")
#end
