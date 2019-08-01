namespace :db do
  desc "Kill all idle connections to the database"
  task killall: [:environment, :check_protected_environments] do
    begin
      configuration = ActiveRecord::Base.configurations[Rails.env]
      sql = "
        SELECT pg_terminate_backend(pg_stat_activity.pid)
        FROM pg_stat_activity
        WHERE datname='#{configuration['database']}' AND state='idle';
      ".squish

      ActiveRecord::Base.connection.select_all(sql)
    rescue ActiveRecord::NoDatabaseError
      puts "Database #{configuration['database']} not found"
    end
  end
end
