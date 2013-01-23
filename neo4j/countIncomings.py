#count incomings of al wiki titles

from neo4j import GraphDatabase
db = GraphDatabase("/mnt/neo4j_full")

def writeIncomings(arr):
	arr.sort(key=lambda v:v[2], reverse=True)
	with open('/home/ubuntu/incomings', 'w') as f:
        	for e in arr:
                	f.write(e[0] + ", " + str(e[1])+", "+str(e[2])+"\n")

i = 0
for anode in db.nodes:
	i += 1
	arr.append((anode.get('url',"unknown"), anode.get('title',"unknown"), len(anode.LINKS_TO.incoming)))
	if i % 500 == 0:
		print i
	if i % 1000 == 0:
		writeIncomings(arr)
	
writeIncomings(arr)

db.shutdown()

