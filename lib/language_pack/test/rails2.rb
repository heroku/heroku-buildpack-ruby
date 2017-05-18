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
    # need to clear db:create before db:schema:load_if_ruby gets called by super
    topic "Clearing #{db_test_tasks_to_clear.join(" ")} rake tasks"
    clear_db_test_tasks
    super
  end

  def db_test_tasks_to_clear
    # db:test:purge is called by everything in the db:test namespace
    # db:create is called by :db:schema:load_if_ruby
    # db:structure:dump is not needed for tests, but breaks Rails 3.2 db:structure:load on Heroku
    ["db:test:purge", "db:create", "db:structure:dump"]
  end

  # rails test runner + rspec depend on db:test:purge which drops/creates a db which doesn't work on Heroku's DB plans
  def clear_db_test_tasks
    FileUtils::mkdir_p 'lib/tasks'
    File.open("lib/tasks/heroku_clear_tasks.rake", "w") do |file|
      content = db_test_tasks_to_clear.map do |task_name|
        <<-FILE
Rake::Task['#{task_name}'].clear
task '#{task_name}' do
end
FILE
      end.join("\n")
      file.print content
    end
  end
end
