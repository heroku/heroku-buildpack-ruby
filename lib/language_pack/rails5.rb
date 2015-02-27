require 'securerandom'
require "language_pack"
require "language_pack/rails42"

class LanguagePack::Rails5 < LanguagePack::Rails42
  # @return [Boolean] true if it's a Rails 5.x app
  def self.use?
    instrument "rails5.use" do
      rails_version = bundler.gem_version('railties')
      return false unless rails_version
      is_rails = rails_version >= Gem::Version.new('5.0.0') &&
                 rails_version <  Gem::Version.new('6.0.0')
      return is_rails
    end
  end
end
