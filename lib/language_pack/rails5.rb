require 'securerandom'
require "language_pack"

class LanguagePack::Rails5 < LanguagePack::Rails4
  # @return [Boolean] true if it's a Rails 5.x app
  def self.use?(bundler:)
    rails_version = bundler.gem_version('railties')
    return false unless rails_version
    is_rails = rails_version >= Gem::Version.new('5.x') &&
                rails_version <  Gem::Version.new('6.0.0')
    return is_rails
  end

  def install_plugins
    # do not install plugins, do not call super, do not warn
  end
end
