require 'rubygems'
require 'neography'

@neo = Neography::Rest.new

class Article
	attr_accessor :id
	attr_accessor :node
	
	def initialize(node)
		@node = node
		@id = @node["self"].split("/").last

	end
	
	def getId()
		return @id
	end
	
	def getTitle()
		return @node["data"]["title"]
	end
	
	def getUrl()
		return @node["data"]["url"]
	end
end

def createArticle(title, url)
  Article.new(@neo.create_node("title" => title, "url" => url))
end

def linkArticles(article1, article2)
  @neo.create_relationship("has_link_to", article1.node, article2.node)
end

def getArticle(id)
  Article.new(@neo.get_node(id))
end

def countLinks(article, dir)
	
	@neo.get_node_relationships(article.id, dir).size

end


def getArticleByTitle(title)
	cypher_query = " START n=node(*)" 
	cypher_query << " WHERE n.title = "
	cypher_query << "'" + title + "'"
	cypher_query << " RETURN n"
	
	Article.new(@neo.execute_query(cypher_query)["data"][0][0]) #only one

end

def countAllLinks()
	cypher_query = " START n=node(*)" 
	cypher_query << " RETURN n"
	
	nodes = @neo.execute_query(cypher_query)["data"]
	
	nodes.each do |node| 
		a = Article.new(node[0])
		puts "IN >>#{countLinks(a,"in")}>> " + a.getTitle() + " >>#{countLinks(a,"out")}>> OUT"
	end
end

def findArticlePaths(startArticle, destinationArticle)
  paths = @neo.get_paths(startArticle.node,
                          destinationArticle.node,
                          {"type"=> "has_link_to", "direction" => "out"},
                          depth=10,
                          algorithm="allSimplePaths") # "allPaths", "allSimplePaths", "shortestPath", "allPaths", "allSimplePaths", "shortestPath"

 paths.each do |p|
 	p["x"] = p["nodes"].collect { |node|
		@neo.get_node_properties(node) }
 end
end

def printPaths(articleA, articleH)
	findArticlePaths(articleA, articleH).each do |path|

	  path["x"].each do |a|
		print " => " + a["title"]
	  end
	  puts " [#{(path["x"].size - 1 )} Schritte]"
	  
	end
end


articleA = createArticle('A','http://de.wikipedia.org/A')
articleB = createArticle('B','http://de.wikipedia.org/B')
articleC = createArticle('C','http://de.wikipedia.org/C')
articleD = createArticle('D','http://de.wikipedia.org/D')
articleE = createArticle('E','http://de.wikipedia.org/E')
articleF = createArticle('F','http://de.wikipedia.org/F')
articleG = createArticle('G','http://de.wikipedia.org/G')
articleH = createArticle('H','http://de.wikipedia.org/H')

linkArticles(articleA, articleB)
linkArticles(articleB, articleC)
linkArticles(articleC, articleD)
linkArticles(articleD, articleE)
linkArticles(articleE, articleF)
linkArticles(articleF, articleG)
linkArticles(articleG, articleH)

linkArticles(articleC, articleF)

linkArticles(articleH, articleF)
linkArticles(articleF, articleC)
linkArticles(articleC, articleA)


articleA = getArticleByTitle("A")
articleH = getArticleByTitle("H")

printPaths(articleA, articleH)
