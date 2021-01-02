namespace :db do
  desc "Rebuild counter caches for users and papers"
  task rebuild_counter_caches: :environment do
    puts "Counting scites..."
    rows = ActiveRecord::Base.connection.execute("SELECT papers.uid, count(*) FROM papers JOIN scites ON (scites.paper_uid = papers.uid) GROUP BY papers.uid;")

    rows.each_with_index do |row, i|
      puts i if i > 0 && i % 1000 == 0
      Paper.where(uid: row['uid']).update_all(scites_count: row['count'])
    end

    puts "Counting comments..."
    rows = ActiveRecord::Base.connection.execute("SELECT papers.uid, count(*) FROM papers JOIN comments ON (comments.paper_uid = papers.uid AND comments.deleted IS FALSE AND comments.hidden IS FALSE) GROUP BY papers.uid;")

    rows.each_with_index do |row, i|
      puts i if i > 0 && i % 1000 == 0
      Paper.where(uid: row['uid']).update_all(comments_count: row['count'])
    end

    # The above doesn't cover papers which need count 0 but have count > 0

    ActiveRecord::Base.connection.execute("UPDATE papers SET scites_count=0 WHERE scites_count != 0 AND NOT EXISTS (SELECT scites.id FROM scites WHERE scites.paper_uid = papers.uid);")

    ActiveRecord::Base.connection.execute("UPDATE papers SET comments_count=0 WHERE comments_count != 0 AND NOT EXISTS (SELECT comments.id FROM comments WHERE comments.paper_uid = papers.uid AND comments.deleted IS FALSE AND comments.hidden IS FALSE);")
  end
end
