wget http://dumps.wikimedia.org/dewiki/latest/dewiki-latest-all-titles-in-ns0.gz
gunzip dewiki-latest-all-titles-in-ns0.gz
ruby titles2redis.rb dewiki-latest-all-titles-in-ns0
rm dewiki-latest-all-titles-in-ns0
