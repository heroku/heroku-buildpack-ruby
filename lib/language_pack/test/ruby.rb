# Opens up the class of the Ruby language pack and
# overwrites methods defined in `language_pack/ruby.rb`
#
# Other "test packs" futher extend this behavior by hooking into
# methods or over writing methods defined here.
class LanguagePack::Ruby
  def compile
    @outdated_version_check = LanguagePack::Helpers::OutdatedRubyVersion.new(
      current_ruby_version: ruby_version,
      fetcher: LanguagePack::Installers::HerokuRubyInstaller.fetcher(multi_arch_stacks: MULTI_ARCH_STACKS, stack: stack, arch: @arch),
    ).call
    @warn_io.warnings.each { |warning| self.warnings << warning }
    post_bundler(ruby_version: @ruby_version, app_path: app_path)
    create_database_yml
    install_binaries
    prepare_tests
    default_config_vars = self.class.default_config_vars(metadata: @metadata, ruby_version: @ruby_version, bundler: bundler, environment_name: environment_name)
    setup_profiled(ruby_layer_path: "$HOME", gem_layer_path: "$HOME", ruby_version: @ruby_version, default_config_vars: default_config_vars) # $HOME is set to /app at run time
    setup_export(app_path: app_path, ruby_version: @ruby_version, default_config_vars: default_config_vars)
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
