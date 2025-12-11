require 'securerandom'
require "language_pack"
require "language_pack/rails5"

class LanguagePack::Rails6 < LanguagePack::Rails5
  # @return [Boolean] true if it's a Rails 6.x app
  def self.use?(bundler:)
    rails_version = bundler.gem_version('railties')
    return false unless rails_version
    is_rails = rails_version >= Gem::Version.new('6.x') &&
      rails_version < Gem::Version.new('7.a')
    return is_rails
  end

  def compile
    FileUtils.mkdir_p("tmp/pids")
    super
  end
end
