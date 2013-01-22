from neo4j import GraphDatabase
import traceback
import time
import redis

r = redis.StrictRedis(host='46.137.39.99', port=6379, db=0)
#r = redis.ConnectionPool(host='46.137.39.99', port=6379, db=0)
cypherRedisKey = r.get("cypherQueries")

db = GraphDatabase("/mnt/neo4py_store/data/graph.db")
#while True:
try:
	#db = GraphDatabase("/mnt/neo4py_store/data/graph.db")
	cypher_query = ""
	while cypher_query is not None:
		print "query found"
		cypher_query = r.rpop(cypherRedisKey)
		if cypher_query is not None:
			db.query(cypher_query)
	#db.shutdown()
	print "sleeping..."
	time.sleep(10)
except Exception, e:
	logfile = open('./pythonError.log', 'a')
	#logfile.write(traceback.format_exc)
	logfile.write("\n"+e.message())
	logfile.close()

db.shutdown()
