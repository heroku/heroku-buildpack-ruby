require "language_pack"
require "language_pack/rails41"

class LanguagePack::Rails42 < LanguagePack::Rails41
  # detects if this is a Rails 4.2 app
  # @return [Boolean] true if it's a Rails 4.2 app
  def self.use?
    instrument "rails42.use" do
      rails_version = bundler.gem_version('railties')
      return false unless rails_version
      is_rails42 = rails_version >= Gem::Version.new('4.2.0') &&
                   rails_version <  Gem::Version.new('5.0.0')
      return is_rails42
    end
  end

  def setup_profiled
    instrument 'setup_profiled' do
      super
      set_env_default "RAILS_SERVE_STATIC_FILES", "enabled"
    end
  end

  def default_config_vars
    super.merge({
      "RAILS_SERVE_STATIC_FILES"  => env("RAILS_SERVE_STATIC_FILES") || "enabled"
    })
  end

  def node_modules_folder
    "node_modules"
  end

  def run_assets_precompile_rake_task
    instrument "rails42.run_assets_precompile_rake_task" do
      log("assets_precompile") do
        if Dir.glob("public/assets/{.sprockets-manifest-*.json,manifest-*.json}", File::FNM_DOTMATCH).any?
          puts "Detected manifest file, assuming assets were compiled locally"
          return true
        end

        precompile = rake.task("assets:precompile")
        return true unless precompile.is_defined?

        topic("Preparing app for Rails asset pipeline")

        @cache.load_without_overwrite public_assets_folder
        @cache.load default_assets_cache
        @cache.load node_modules_folder

        precompile.invoke(env: rake_env)

        if precompile.success?
          log "assets_precompile", :status => "success"
          puts "Asset precompilation completed (#{"%.2f" % precompile.time}s)"

          puts "Cleaning assets"
          rake.task("assets:clean").invoke(env: rake_env)

          cleanup_assets_cache
          @cache.store public_assets_folder
          @cache.store default_assets_cache
          @cache.store node_modules_folder
        else
          precompile_fail(precompile.output)
        end
      end
    end
  end
end
