require 'securerandom'
require "language_pack"
require "language_pack/rails5"

class LanguagePack::Rails51 < LanguagePack::Rails5
  NODE_MODULES_PATH = 'node_modules'
  WEBPACKER_CACHE_PATH = 'tmp/cache/webpacker'
  YARN_CACHE_PATH = '~/.yarn-cache'

  # @return [Boolean] true if it's a Rails 5.1.x app
  def self.use?
    instrument "rails51.use" do
      rails_version = bundler.gem_version('railties')
      return false unless rails_version
      is_rails = rails_version >= Gem::Version.new('5.1.x')
      return is_rails
    end
  end

  private

    def run_assets_precompile_rake_task
      instrument "rails51.run_assets_precompile_rake_task" do
        log("assets_precompile") do
          if Dir.glob("public/assets/{.sprockets-manifest-*.json,manifest-*.json}", File::FNM_DOTMATCH).any?
            puts "Detected manifest file, assuming assets were compiled locally"
            return true
          end

          precompile = rake.task("assets:precompile")
          return true unless precompile.is_defined?

          topic("Preparing app for Rails asset pipeline")

          load_asset_cache

          precompile.invoke(env: rake_env)

          if precompile.success?
            log "assets_precompile", :status => "success"
            puts "Asset precompilation completed (#{"%.2f" % precompile.time}s)"

            puts "Cleaning assets"
            rake.task("assets:clean").invoke(env: rake_env)

            cleanup_assets_cache
            store_asset_cache
          else
            precompile_fail(precompile.output)
          end
        end
      end
    end

    def load_asset_cache
      puts "Loading asset cache"
      @cache.load_without_overwrite public_assets_folder
      @cache.load default_assets_cache
      @cache.load NODE_MODULES_PATH
      @cache.load YARN_CACHE_PATH
      @cache.load WEBPACKER_CACHE_PATH
    end

    def store_asset_cache
      puts "Storing asset cache"
      @cache.store public_assets_folder
      @cache.store default_assets_cache
      @cache.store NODE_MODULES_PATH
      @cache.store YARN_CACHE_PATH
      @cache.store WEBPACKER_CACHE_PATH
    end

    def cleanup
      # does not call super because it would return if default_assets_cache was missing
      return if assets_compile_enabled?

      puts "Removing non-essential asset cache directories"
      FileUtils.remove_dir(default_assets_cache) if Dir.exist?(default_assets_cache)
      FileUtils.remove_dir(NODE_MODULES_PATH) if Dir.exist?(NODE_MODULES_PATH)
      FileUtils.remove_dir(YARN_CACHE_PATH) if Dir.exist?(YARN_CACHE_PATH)
      FileUtils.remove_dir(WEBPACKER_CACHE_PATH) if Dir.exist?(WEBPACKER_CACHE_PATH)
    end
end
