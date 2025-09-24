require "language_pack"
require "language_pack/rails41"

class LanguagePack::Rails42 < LanguagePack::Rails41
  # detects if this is a Rails 4.2 app
  # @return [Boolean] true if it's a Rails 4.2 app
  def self.use?
    rails_version = bundler.gem_version('railties')
    return false unless rails_version
    is_rails42 = rails_version >= Gem::Version.new('4.2.0') &&
                  rails_version <  Gem::Version.new('5.0.0')
    return is_rails42
  end

  # Environment variable defaults that are passet to ENV and `.profile.d`
  #
  # All values returned must be sourced from Heroku. User provided config vars
  # are handled in the interfaces that consume this method's result.
  #
  # @return [Hash] the ENV var like result
  def default_config_vars
    out = super # Inherited from LanguagePack::Rails41
    out["RAILS_SERVE_STATIC_FILES"] = "enabled"
    out
  end
end
