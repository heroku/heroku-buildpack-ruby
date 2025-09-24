require 'securerandom'
require "language_pack"
require "language_pack/rails4"

class LanguagePack::Rails41 < LanguagePack::Rails4
  # detects if this is a Rails 4.x app
  # @return [Boolean] true if it's a Rails 4.x app
  def self.use?
    rails_version = bundler.gem_version('railties')
    return false unless rails_version
    is_rails4 = rails_version >= Gem::Version.new('4.1.0.beta1') &&
                rails_version <  Gem::Version.new('5.0.0')
    return is_rails4
  end

  # Environment variable defaults that are passet to ENV and `.profile.d`
  #
  # All values returned must be sourced from Heroku. User provided config vars
  # are handled in the interfaces that consume this method's result.
  #
  # @return [Hash] the ENV var like result
  def default_config_vars
    out = super # Inherited from LanguagePack::Rails4
    out["SECRET_KEY_BASE"] = app_secret
    out
  end

  private
  def app_secret
    key = "secret_key_base"

    @app_secret ||= begin
      if @metadata.exists?(key)
        @metadata.read(key).strip
      else
        secret = SecureRandom.hex(64)
        @metadata.write(key, secret)

        secret
      end
    end
  end
end
