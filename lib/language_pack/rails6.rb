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

  def node_modules_folder
    "node_modules"
  end

  def public_packs_folder
    "public/packs"
  end

  def webpacker_cache_folder
    "tmp/cache/webpacker"
  end

  def restore_precompiled_assets
    @cache.load_without_overwrite public_packs_folder
    @cache.load node_modules_folder
    @cache.load webpacker_cache_folder
    super
  end

  def save_precompiled_assets
    @cache.store public_packs_folder
    @cache.store node_modules_folder
    @cache.store webpacker_cache_folder
    super
  end

  def compile
    instrument "rails6.compile" do
      FileUtils.mkdir_p("tmp/pids")
      super
    end
  end
end
