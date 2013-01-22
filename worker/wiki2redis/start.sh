wget http://dumps.wikimedia.org/dewiki/latest/dewiki-latest-all-titles-in-ns0.gz
gunzip dewiki-latest-all-titles-in-ns0.gz
ruby wiki_titles_to_redis.rb dewiki-latest-all-titles-in-ns0
rm dewiki-latest-all-titles-in-ns0
