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
    schema_load = rake.task("db:schema:load")
    db_migrate  = rake.task("db:migrate")
    return true unless (schema_load.is_defined? || db_migrate.is_defined?)

    topic "Preparing test database schema"

    [schema_load, db_migrate].each do |rake_task|
      if rake_task.is_defined?
        rake_task.invoke(env: rake_env)
        if rake_task.success?
          puts "#{rake_task.task} completed (#{"%.2f" % rake_task.time}s)"
        else
          error "Could not load test database schema"
        end
      end
    end
  end
end
