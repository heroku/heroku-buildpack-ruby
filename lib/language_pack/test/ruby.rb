# Opens up the class of the Ruby language pack and
# overwrites methods defined in `language_pack/ruby.rb`
#
# Other "test packs" futher extend this behavior by hooking into
# methods or over writing methods defined here.
class LanguagePack::Ruby
  def compile
    @ruby_version = self.class.get_ruby_version(
      metadata: @metadata,
      report: @report,
      gemfile_lock: @gemfile_lock
    )
    self.class.install_ruby_bundle_install(
      app_path: app_path,
      metadata: @metadata,
      bundler_version: bundler.version,
      warn_io: @warn_io,
      ruby_version: @ruby_version,
      stack: @stack,
      arch: @arch,
      user_env_hash: user_env_hash,
      default_config_vars: default_config_vars,
      new_app: new_app?,
      cache: @cache,
      bundler_cache: @bundler_cache,
      bundle_default_without: "development",
    )

    @warn_io.warnings.each { |warning| self.warnings << warning }
    post_bundler
    create_database_yml
    install_binaries
    prepare_tests
    setup_profiled(ruby_layer_path: "$HOME", gem_layer_path: "$HOME") # $HOME is set to /app at run time
    setup_export
    super
  end

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
