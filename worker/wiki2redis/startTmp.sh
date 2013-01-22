wget http://dumps.wikimedia.org/dewiki/latest/dewiki-latest-all-titles-in-ns0.gz
gunzip dewiki-latest-all-titles-in-ns0.gz
ruby wiki_to_tmp.rb dewiki-latest-all-titles-in-ns0
rm dewiki-latest-all-titles-in-ns0
