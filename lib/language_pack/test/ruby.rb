#module LanguagePack::Test::Ruby
class LanguagePack::Ruby
  def compile
    instrument 'ruby.test.compile' do
      new_app?
      Dir.chdir(build_path)
      remove_vendor_bundle
      warn_bad_binstubs
      install_ruby(slug_vendor_ruby, build_ruby_path)
      setup_language_pack_environment(
        ruby_layer_path: File.expand_path("."),
        gem_layer_path: File.expand_path("."),
        bundle_path: "vendor/bundle",
        bundle_default_without: "development"
      )
      setup_export
      allow_git do
        install_bundler_in_app(slug_vendor_base)
        load_bundler_cache
        build_bundler
        post_bundler
        create_database_yml
        install_binaries
        prepare_tests
      end
      setup_profiled(ruby_layer_path: "$HOME", gem_layer_path: "$HOME") # $HOME is set to /app at run time
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
