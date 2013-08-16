require "fileutils"
require "language_pack"
require "language_pack/rack"

# Rails 2 Language Pack. This is for any Rails 2.x apps.
class LanguagePack::Rails2 < LanguagePack::Ruby
  # detects if this is a valid Rails 2 app
  # @return [Boolean] true if it's a Rails 2 app
  def self.use?
    instrument "rails2.use" do
      if gemfile_lock?
        rails_version = LanguagePack::Ruby.gem_version('rails')
        rails_version >= Gem::Version.new('2.0.0') && rails_version < Gem::Version.new('3.0.0') if rails_version
      end
    end
  end

  def name
    "Ruby/Rails"
  end

  def default_config_vars
    instrument "rails2.default_config_vars" do
      super.merge({
        "RAILS_ENV" => "production",
        "RACK_ENV" => "production"
      })
    end
  end

  def default_process_types
    instrument "rails2.default_process_types" do
      web_process = gem_is_bundled?("thin") ?
        "bundle exec thin start -e $RAILS_ENV -p $PORT" :
        "bundle exec ruby script/server -p $PORT"

      super.merge({
        "web" => web_process,
        "worker" => "bundle exec rake jobs:work",
        "console" => "bundle exec script/console"
      })
    end
  end

  def compile
    instrument "rails2.compile" do
      install_plugins
      super
    end
  end

private

  def install_plugins
    instrument "rails2.install_plugins" do
      plugins = ["rails_log_stdout"].reject { |plugin| gem_is_bundled?(plugin) }
      topic "Rails plugin injection"
      LanguagePack::Helpers::PluginsInstaller.new(plugins).install
    end
  end

  # most rails apps need a database
  # @return [Array] shared database addon
  def add_dev_database_addon
    ['heroku-postgresql:dev']
  end

  # sets up the profile.d script for this buildpack
  def setup_profiled
    super
    set_env_default "RACK_ENV",  "production"
    set_env_default "RAILS_ENV", "production"
  end

end
