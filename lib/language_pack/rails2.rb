require "fileutils"
require "language_pack"
require "language_pack/rack"

# Rails 2 Language Pack. This is for any Rails 2.x apps.
class LanguagePack::Rails2 < LanguagePack::Ruby
  # detects if this is a valid Rails 2 app
  # @return [Boolean] true if it's a Rails 2 app
  def self.use?
    rails_version = bundler.gem_version('rails')
    return false unless rails_version
    is_rails2 = rails_version >= Gem::Version.new('2.0.0') &&
                rails_version <  Gem::Version.new('3.0.0')
    return is_rails2
  end

  def initialize(*args)
    super(*args)
    @rails_runner = LanguagePack::Helpers::RailsRunner.new
  end

  def name
    "Ruby/Rails"
  end

  def default_env_vars
    {
      "RAILS_ENV" => "production",
      "RACK_ENV" => "production"
    }
  end

  def default_config_vars
    config_vars = super
    default_env_vars.map do |key, value|
      config_vars[key] = env(key) || value
    end
    config_vars
  end

  def default_process_types
    web_process = bundler.has_gem?("thin") ?
      "bundle exec thin start -e $RAILS_ENV -p ${PORT:-5000}" :
      "bundle exec ruby script/server -p ${PORT:-5000}"

    process_types = super
    process_types["web"]     = web_process
    process_types["worker"]  = "bundle exec rake jobs:work" if has_jobs_work_task?
    process_types["console"] = "bundle exec script/console"
    process_types
  end

  def compile
    install_plugins
    super
  end

  def build
    # TODO install plugins into separate layer
    install_plugins
    super
  end

  def best_practice_warnings
    if env("RAILS_ENV") != "production"
      warn(<<-WARNING)
You are deploying to a non-production environment: #{ env("RAILS_ENV").inspect }.
This is not recommended.
See https://devcenter.heroku.com/articles/deploying-to-a-custom-rails-environment for more information.
WARNING
    end
    super
  end

private
  def has_jobs_work_task?
    if result = rake.task("jobs:work").is_defined?
      mcount("task.jobs:work.enabled")
    else
      mcount("task.jobs:work.disabled")
    end
    result
  end

  def install_plugins
    plugins = ["rails_log_stdout"].reject { |plugin| bundler.has_gem?(plugin) }
    topic "Rails plugin injection"
    LanguagePack::Helpers::PluginsInstaller.new(plugins).install
  end

  # sets up the profile.d script for this buildpack
  def setup_profiled(*args)
    super(*args)
    default_env_vars.each do |key, value|
      set_env_default key, value
    end
  end

end
