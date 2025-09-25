require "language_pack"
require "language_pack/ruby"

# Rack Language Pack. This is for any non-Rails Rack apps like Sinatra.
class LanguagePack::Rack < LanguagePack::Ruby

  # detects if this is a valid Rack app by seeing if "config.ru" exists
  # @return [Boolean] true if it's a Rack app
  def self.use?
    bundler.gem_version('rack')
  end

  def name
    "Ruby/Rack"
  end

  # Environment variable defaults that are passet to ENV and `.profile.d`
  #
  # All values returned must be sourced from Heroku. User provided config vars
  # are handled in the interfaces that consume this method's result.
  #
  # @return [Hash] the ENV var like result
  def default_config_vars
    out = super
    out["RACK_ENV"] = "production"
    out
  end

  def default_process_types
    # let's special case thin here if we detect it
    web_process = bundler.has_gem?("thin") ?
      "bundle exec thin start -R config.ru -e $RACK_ENV -p ${PORT:-5000}" :
      "bundle exec rackup config.ru -p ${PORT:-5000}"

    super.merge({
      "web" => web_process
    })
  end
end
