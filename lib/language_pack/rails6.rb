require 'securerandom'
require "language_pack"
require "language_pack/rails5"

class LanguagePack::Rails6 < LanguagePack::Rails5
  # @return [Boolean] true if it's a Rails 6.x app
  def self.use?
    instrument "rails6.use" do
      rails_version = bundler.gem_version('railties')
      return false unless rails_version
      is_rails = rails_version >= Gem::Version.new('6.x') &&
        rails_version < Gem::Version.new('7.0.0')
      return is_rails
    end
  end

  def compile
    instrument "rails6.compile" do
      FileUtils.mkdir_p("tmp/pids")
      super
    end
  end
end
