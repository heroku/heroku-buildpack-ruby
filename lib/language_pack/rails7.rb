require 'securerandom'
require "language_pack"
require "language_pack/rails6"

class LanguagePack::Rails7 < LanguagePack::Rails6
  # @return [Boolean] true if it's a Rails 7.x app
  def self.use?(bundler:)
    rails_version = bundler.gem_version('railties')
    return false unless rails_version
    is_rails = rails_version >= Gem::Version.new('7.a') &&
      rails_version < Gem::Version.new('8.a')
    return is_rails
  end
end
