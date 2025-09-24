require 'securerandom'
require "language_pack"
require "language_pack/rails42"

class LanguagePack::Rails5 < LanguagePack::Rails42
  # @return [Boolean] true if it's a Rails 5.x app
  def self.use?
    rails_version = bundler.gem_version('railties')
    return false unless rails_version
    is_rails = rails_version >= Gem::Version.new('5.x') &&
                rails_version <  Gem::Version.new('6.0.0')
    return is_rails
  end

  def default_config_vars
    out = super # Inherited from LanguagePack::Rails42
    out["RAILS_LOG_TO_STDOUT"] = "enabled"
    out
  end

  def install_plugins
    # do not install plugins, do not call super, do not warn
  end
end
