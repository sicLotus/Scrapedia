#put xml data from redis in neo4j database

from neo4j import GraphDatabase 
from xml.dom.minidom import parseString 
import redis 
import time

db = GraphDatabase("/mnt/neo4j_full") 
r = redis.StrictRedis(host='176.34.212.62', port=6379, db=0) 
cypherRedisKey = r.get("cypherQueries") 
start_time = time.clock() 
nodes = 0 

def create_page(url, title):
	page = get_page(url)
	if not page:
		page = db.node(url=url, title=title)
		page.INSTANCE_OF(pages)
		page_idx['url'][url] = page
	return page 

def link_to(page, forwarding, url, title):
	linkTo = get_page(url)
	if not linkTo:
		linkTo = create_page(url,title)
	else:
		linkTo['title'] = title
	if forwarding == "true":
		page.FORWARDS_TO(linkTo)
	else:
		page.LINKS_TO(linkTo)
	return linkTo
	
def get_page(url):
	return page_idx['url'][url].single

def createIndex():
	with db.transaction:
		pages = db.node()
		db.reference_node.PAGES(pages)
		page_idx = db.node.indexes.create('pages')

with db.transaction:
	pages = db.getNodeById(1)
	if db.node.indexes.exists('pages'):
		page_idx = db.node.indexes.get('pages')
	else:
		createIndex()

while True:
	if nodes % 100 == 0:
		print "Running Time: "+str(time.clock()-start_time)+"\nNodes: "+str(nodes)

	query = r.rpop(cypherRedisKey)
	
	if query is None:
		time.sleep(10)
		continue;
		
	dom = parseString(query)
	articleTitle = dom.getElementsByTagName('at')[0].firstChild.data
	articleURL = dom.getElementsByTagName('au')[0].firstChild.data
	forwarding = dom.getElementsByTagName('fw')[0].firstChild.data
	
	with db.transaction:
		articlePage = create_page(articleURL, articleTitle)
		nodes += 1
		linkTitles = dom.getElementsByTagName('lt')
		linkURLs = dom.getElementsByTagName('lu')
	
		for i in range(0,linkTitles.length):
			linkTitle = linkTitles[i].firstChild.data
			linkURL = linkURLs[i].firstChild.data
			link_to(articlePage,forwarding,linkURL,linkTitle)
	
db.shutdown()
