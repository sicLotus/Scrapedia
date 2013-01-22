require 'rubygems'
require 'aws-sdk'

AWS.config(
  :access_key_id => "AKIAJJDOQK5QYCVP6CNQ",
  :secret_access_key => "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"
)

s3 = AWS::S3.new

#defaultValues = ["testfile.txt", ", ", 20, "statistics.json", "scrapedia", "statistics.json", "[", "['%title', '<a href=\"%url\">%title</a>', '%number']", ", ", "]"]
removeFromURL = "http://de.wikipedia.org/wiki/"

def showHelp
	puts "args:"
	puts ">>> uploadStatistics.rb <input file> <separator> <n> <output> <bucket> <key> <pattern start> <pattern row> <pattern separator> <pattern end>"
	puts
	puts "example call:"
	puts '>>> uploadStatistics.rb testfile.txt ", " 20 "statistics.json" "scrapedia" "statistics.json" "[" "[\'%title\', \'<a href="%url">%title</a>\', \'%number\']" ", " "]"'
	puts
end

def readFirstLinesFromFile(file, n=20)
	open(file) do |f|
		lines = []
		n.times do
			line = f.gets || break
			lines << line
		end
		lines
	end
end

def uploadFileToS3(s3, file, bucket, key)
	b = s3.buckets.create(bucket)
	o = b.objects[key]
	o.write(:file => file, :acl => :public_read)
	o.public_url
end


if ARGV.length != 10
	showHelp
	exit
else
	localInputFile = ARGV[0]
	elementSeparator = ARGV[1]
	readNEntries = ARGV[2].to_i
	localOutputFile = ARGV[3]
	bucketName = ARGV[4]
	s3Key = ARGV[5]

	patternStart = ARGV[6]
	patternRow = ARGV[7]
	patternSeparator = ARGV[8]
	puts patternSeparator
	patternEnd = ARGV[9]
end

lines = readFirstLinesFromFile(localInputFile, readNEntries)

result = patternStart

lines.each_with_index  do |line, i|
	result += (i > 0) ? patternSeparator : ""
	
	line = line.gsub("\n", "")
	split_str = line.split(elementSeparator)

	url =  split_str[0]
	title =  url.gsub(removeFromURL, "").gsub("_", " ")
	number = split_str[1]
	
	row = patternRow.gsub('%url', url).gsub('%title', title).gsub('%number', number)
	
	result += row
end

result += patternEnd

open(localOutputFile, 'w') do |f| 
	f.write(result)
end

puts uploadFileToS3(s3, localOutputFile, bucketName, s3Key)
