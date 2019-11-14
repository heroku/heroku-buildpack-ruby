require 'securerandom'
require 'language_pack'
require 'language_pack/rails5'

class LanguagePack::Rails51 < LanguagePack::Rails5
  ASSET_PATHS = %w[
    public/packs
    ~/.yarn-cache
    ~/.cache/yarn
  ]

  ASSET_CACHE_PATHS = %w[
    node_modules
    tmp/cache/webpacker
  ]

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

      paths = (self.class::ASSET_PATHS + self.class::ASSET_CACHE_PATHS)
      paths.each { |path| @cache.load path }
    end

    def store_asset_cache
      puts "Storing asset cache"
      @cache.store public_assets_folder
      @cache.store default_assets_cache

      paths = (self.class::ASSET_PATHS + self.class::ASSET_CACHE_PATHS)
      paths.each { |path| @cache.store path }
    end

    def cleanup
      # does not call super because it would return if default_assets_cache was missing
      #   child classes should call super and should not use a return statement
      return if assets_compile_enabled?

      puts "Removing non-essential asset cache directories"

      FileUtils.remove_dir(default_assets_cache) if Dir.exist?(default_assets_cache)

      self.class::ASSET_CACHE_PATHS.each do |path|
        FileUtils.remove_dir(path) if Dir.exist?(path)
      end
    end
end
