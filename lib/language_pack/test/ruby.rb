#module LanguagePack::Test::Ruby
class LanguagePack::Ruby
  def compile
    instrument 'ruby.test.compile' do
      new_app?
      Dir.chdir(build_path)
      remove_vendor_bundle
      install_ruby(slug_vendor_ruby, build_ruby_path)
      install_jvm
      setup_language_pack_environment
      setup_export
      setup_profiled
      allow_git do
        install_bundler_in_app(slug_vendor_base)
        load_bundler_cache
        build_bundler(bundle_path: "vendor/bundle", default_bundle_without: "development")
        post_bundler
        create_database_yml
        install_binaries
        prepare_tests
      end
      super
    end
  end

  private
  def db_prepare_test_rake_tasks
    ["db:schema:load", "db:migrate"].map {|name| rake.task(name) }
  end

  def prepare_tests
    rake_tasks = db_prepare_test_rake_tasks.select(&:is_defined?)
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
end
