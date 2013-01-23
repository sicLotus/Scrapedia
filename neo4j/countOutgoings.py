#count all outgoing links from all nodes

from neo4j import GraphDatabase
db = GraphDatabase("/mnt/neo4j_full")

def writeOutgoings(arr):
	arr.sort(key=lambda v:v[2], reverse=True)
	with open('/home/ubuntu/outgoings', 'w') as f:
        	for e in arr:
                	f.write(e[0] + ", " + str(e[1])+", "+str(e[2])+"\n")

i = 0
for anode in db.nodes:
	i += 1
	arr.append((anode.get('url',"unknown"), anode.get('title',"uknown"), len(anode.LINKS_TO.outgoing)))
	if i % 500 == 0:
		print i
	if i % 1000 == 0:
		writeOutgoings(arr)
	
writeOutgoings(arr)

db.shutdown()