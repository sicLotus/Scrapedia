from neo4j import GraphDatabase 

db = GraphDatabase("/mnt/neo4j_full")

with db.transaction:
	pages = db.node()
	db.reference_node.PAGES(pages)
	page_idx = db.node.indexes.create('pages')

db.shutdown()