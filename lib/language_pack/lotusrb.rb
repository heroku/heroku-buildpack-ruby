require "fileutils"
require "language_pack"
require "language_pack/rack"

# Lotus Language Pack.
class LanguagePack::Lotus < LanguagePack::Rack
  # detects if this is a valid Lotus app
  # @return [Boolean] true if it's a Lotus app
  def self.use?
    instrument "lotusrb.use" do
      lotusrb_version = bundler.gem_version('lotusrb')
      return false unless lotusrb_version
      return lotusrb_version >= Gem::Version.new('0.6.0')
    end
  end

  def name
    "Ruby/Lotus"
  end

  def default_config_vars
    instrument "lotusrb.default_config_vars" do
      super.merge({
        "LOTUS_ENV" => env("LOTUS_ENV") || "production",
        "SERVE_STATIC_ASSETS"  => env("SERVE_STATIC_ASSETS") || "true"
      })
    end
  end

  def default_process_types
    instrument "lotus.default_process_types" do
      web_process = bundler.has_gem?("puma") ?
        "bundle exec puma -e $LOTUS_ENV -p $PORT" :
        "bundle exec lotus server -p $PORT"

      super.merge({
        "web" => web_process,
        "console" => "bundle exec lotus console"
      })
    end
  end

  def compile
    instrument "lotusrb.compile" do
      super
    end
  end

private

  def create_database_yml
    # do nothing
  end

  # run the `lotus assets precompile` command
  def run_assets_precompile_rake_task

  end

  def best_practice_warnings
    if env("LOTUS_ENV") != "production"
      warn(<<-WARNING)
You are deploying to a non-production environment: #{ env("LOTUS_ENV").inspect }.
WARNING
    end
    super
  end

private

  # sets up the profile.d script for this buildpack
  def setup_profiled
    super
    set_env_default "LOTUS_ENV", "production"
  end

end
