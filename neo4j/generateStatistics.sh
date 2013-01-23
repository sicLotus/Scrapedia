#! /bin/sh

#http://ec2-54-246-66-235.eu-west-1.compute.amazonaws.com:8088/statistics/top20/mostlinked
#[['Artikel1', '<a href="url1">Article1</a>', 'linkedNumber'],['Artikel2', '<a href="url2">Article2</a>', 'linkedNumber'],['Artikel3', '<a href="url3">Article3</a>', 'linkedNumber']]
ruby ./uploadStatistics.rb "incomings" ", " 20 "./statistics/top20mostLinked.json" "scrapedia" "top20mostLinked.json" "[" "['%title', '<a href=\"%url\">%title</a>', '%number']" ", " "]"

#http://ec2-54-246-66-235.eu-west-1.compute.amazonaws.com:8088/statistics/top20/mostlinks
#[['Artikel1', '<a href="url1">Article1</a>', 'numberOfLinks'],['Artikel2', '<a href="url2">Article2</a>', 'numberOfLinks'],['Artikel3', '<a href="url3">Article3</a>', 'numberOfLinks']]
ruby uploadStatistics.rb "outgoings" ", " 20 "./statistics/top20mostLinks.json" "scrapedia" "top20mostLinks.json" "[" "['%title', '<a href=\"%url\">%title</a>', '%number']" ", " "]"


#http://ec2-54-246-66-235.eu-west-1.compute.amazonaws.com:8088/statistics/list/unlinked
#<ul><li><a href="url">ArtikelName#1</a></li><li><a href="url">ArtikelName#2</a></li><li><a href="url">ArtikelName#3</a></li></ul>
ruby uploadStatistics.rb "incomings_0" ", " 5000 "./statistics/unlinked.json" "scrapedia" "unlinked.json" "<ul>" "<li><a href=\"%url\">%title</a></li>" "" "</ul>"


#http://ec2-54-246-66-235.eu-west-1.compute.amazonaws.com:8088/statistics/list/nolinks
#<ul><li><a href="url">ArtikelName#1</a></li><li><a href="url">ArtikelName#2</a></li><li><a href="url">ArtikelName#3</a></li></ul>
ruby uploadStatistics.rb "outgoings_0" ", " 5000 "./statistics/nolinks.json" "scrapedia" "nolinks.json" "<ul>" "<li><a href=\"%url\">%title</a></li>" "" "</ul>"

