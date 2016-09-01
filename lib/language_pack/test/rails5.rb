class LanguagePack::Rails5
  def prepare_tests
    if bundler.has_gem?("activerecord")
      topic "Preparing rails test database schema"
      pipe("rails db:schema:load", env: rake_env)
      schema_load_status = $?.success?
      pipe("rails db:migrate", env: rake_env)
      db_migrate_status = $?.success?

      if !schema_load_status or !db_migrate_status
        error "Could not load test database schema"
      end
    end
  end
end
