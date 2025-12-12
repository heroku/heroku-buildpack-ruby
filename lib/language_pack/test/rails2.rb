# Opens up the class of the Rails2 language pack and
# overwrites methods defined in `language_pack/test/ruby.rb`
class LanguagePack::Rails2
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
      file.puts "# rubocop:disable all"
      content = db_test_tasks_to_clear.map do |task_name|
        <<~FILE
          if Rake::Task.task_defined?('#{task_name}')
            Rake::Task['#{task_name}'].clear
            task '#{task_name}' do
            end
          end
        FILE
      end.join("\n")
      file.print content
      file.puts "# rubocop:enable all"
    end
  end

  def db_prepare_test_rake_tasks
    schema_load    = rake.task("db:schema:load_if_ruby")
    structure_load = rake.task("db:structure:load_if_sql")
    db_migrate     = rake.task("db:migrate")

    return [] if db_migrate.not_defined?

    if schema_load.not_defined? && structure_load.not_defined?
      result = detect_schema_format
      case result.lines.last.strip
      when "ruby"
        schema_load    = rake.task("db:schema:load")
      when "sql" # currently not a possible edge case, we think
        structure_load = rake.task("db:structure:load")
      else
        puts "Could not determine schema/structure from `ActiveRecord::Base.schema_format`:\n#{result}"
      end
    end

    [schema_load, structure_load, db_migrate]
  end


  def detect_schema_format
    run("rails runner 'puts ActiveRecord::Base.schema_format'", user_env: true)
  end
end
