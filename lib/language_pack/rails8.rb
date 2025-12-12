require 'securerandom'
require "language_pack"
require "language_pack/rails7"

class LanguagePack::Rails8 < LanguagePack::Rails7
  # @return [Boolean] true if it's a Rails 8.x app
  def self.use?(bundler:)
    rails_version = bundler.gem_version('railties')
    return false unless rails_version
    is_rails = rails_version >= Gem::Version.new('8.a') &&
      rails_version < Gem::Version.new('9.a')
    return is_rails
  end
end
