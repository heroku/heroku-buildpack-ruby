#module LanguagePack::Test::Rails2
class LanguagePack::Rails2
  # sets up the profile.d script for this buildpack
  def setup_profiled
    super
    set_env_default "RACK_ENV",  "test"
    set_env_default "RAILS_ENV", "test"
  end

  def default_env_vars
    {
      "RAILS_ENV" => "test",
      "RACK_ENV"  => "test"
    }
  end

  def rake_env
    super.merge(default_env_vars)
  end

  def prepare_tests
    super
    topic "Clearing db:test:purge rake task"
    blank_db_test_purge_task
  end

  # rails test runner + rspec depend on db:test:purge which drops/creates a db which doesn't work on Heroku's DB plans
  def blank_db_test_purge_task
    File.open("lib/tasks/heroku_db_test_purge.rake", "w") do |file|
      file.puts <<FILE
Rake::Task["db:test:purge"].clear
task "db:test:purge" do
end
FILE
    end
  end
end
