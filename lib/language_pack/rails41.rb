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
end
