#! /bin/sh

#http://ec2-54-246-66-235.eu-west-1.compute.amazonaws.com:8088/statistics/top20/mostlinked
#[['Artikel1', '<a href="url1">Article1</a>', 'linkedNumber'],['Artikel2', '<a href="url2">Article2</a>', 'linkedNumber'],['Artikel3', '<a href="url3">Article3</a>', 'linkedNumber']]
uploadStatistics.rb "top20mostLinked.txt" ", " 20 "top20mostLinked.json" "scrapedia" "top20mostLinked.json" "[" "['%title', '<a href=\"%url\">%title</a>', '%number']" ", " "]"

#http://ec2-54-246-66-235.eu-west-1.compute.amazonaws.com:8088/statistics/top20/mostlinks
#[['Artikel1', '<a href="url1">Article1</a>', 'numberOfLinks'],['Artikel2', '<a href="url2">Article2</a>', 'numberOfLinks'],['Artikel3', '<a href="url3">Article3</a>', 'numberOfLinks']]
uploadStatistics.rb "top20mostLinks.txt" ", " 20 "top20mostLinks.json" "scrapedia" "top20mostLinks.json" "[" "['%title', '<a href=\"%url\">%title</a>', '%number']" ", " "]"


#http://ec2-54-246-66-235.eu-west-1.compute.amazonaws.com:8088/statistics/list/unlinked
#<ul><li><a href="url">ArtikelName#1</a></li><li><a href="url">ArtikelName#2</a></li><li><a href="url">ArtikelName#3</a></li></ul>
uploadStatistics.rb "unlinked.txt" ", " 20 "unlinked.json" "scrapedia" "unlinked.json" "<ul>" "<li><a href=\"%url\">%title</a></li>" "" "</ul>"


#http://ec2-54-246-66-235.eu-west-1.compute.amazonaws.com:8088/statistics/list/nolinks
#<ul><li><a href="url">ArtikelName#1</a></li><li><a href="url">ArtikelName#2</a></li><li><a href="url">ArtikelName#3</a></li></ul>
uploadStatistics.rb "unlinked.txt" ", " 20 "unlinked.json" "scrapedia" "unlinked.json" "<ul>" "<li><a href=\"%url\">%title</a></li>" "" "</ul>"
