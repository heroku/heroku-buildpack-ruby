#module LanguagePack::Test::Ruby
class LanguagePack::Ruby
  def compile
    instrument 'ruby.test.compile' do
      new_app?
      Dir.chdir(build_path)
      remove_vendor_bundle
      install_ruby
      install_jvm
      setup_language_pack_environment
      setup_profiled
      allow_git do
        install_bundler_in_app
        build_bundler("development")
        post_bundler
        create_database_yml
        install_binaries
        prepare_tests
      end
      super
    end
  end

  private
  def prepare_tests
    schema_load    = rake.task("db:schema:load_if_ruby")
    structure_load = rake.task("db:structure:load_if_sql")
    db_migrate     = rake.task("db:migrate")

    if schema_load.not_defined? && structure_load.not_defined?
      result = detect_schema_format
      case result.lines.last.chomp
      when "ruby"
        schema_load    = rake.task("db:schema:load")
      when "sql"
        structure_load = rake.task("db:structure:load")
      else
        puts "Could not determine schema/structure from ActiveRecord::Base.schema_format:\n#{result}"
      end
    end

    rake_tasks = [schema_load, structure_load, db_migrate].select(&:is_defined?)
    return true if rake_tasks.empty?

    topic "Preparing test database"
    rake_tasks.each do |rake_task|
      rake_task.invoke(env: rake_env)
      if rake_task.success?
        puts "#{rake_task.task} completed (#{"%.2f" % rake_task.time}s)"
      else
        error "Could not prepare database for test"
      end
    end
  end


  def detect_schema_format
    run("rails runner 'puts ActiveRecord::Base.schema_format'")
  end
end
