require "language_pack"
require "language_pack/rails3"

# Rails 4 Language Pack. This is for all Rails 4.x apps.
class LanguagePack::Rails4 < LanguagePack::Rails3
  # detects if this is a Rails 3.x app
  # @return [Boolean] true if it's a Rails 3.x app
  def self.use?
    rails_version = LanguagePack::Ruby.gem_version('rails')
    rails_version >= Gem::Version.new('4.0.0') && rails_version < Gem::Version.new('5.0.0') if rails_version
  end

  def name
    "Ruby/Rails"
  end

  private
  def plugins
    []
  end
end
