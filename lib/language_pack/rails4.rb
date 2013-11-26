require "language_pack"
require "language_pack/rails3"

# Rails 4 Language Pack. This is for all Rails 4.x apps.
class LanguagePack::Rails4 < LanguagePack::Rails3
  ASSETS_CACHE_LIMIT = 52428800 # bytes

  # detects if this is a Rails 3.x app
  # @return [Boolean] true if it's a Rails 3.x app
  def self.use?
    instrument "rails4.use" do
      if gemfile_lock?
        rails_version = LanguagePack::Ruby.gem_version('railties')
        return false unless rails_version
        is_rails4     = rails_version >= Gem::Version.new('4.0.0.beta') &&
                        rails_version <  Gem::Version.new('5.0.0')
        return is_rails4
      end
    end
  end

  def name
    "Ruby/Rails"
  end

  def default_process_types
    instrument "rails4.default_process_types" do
      super.merge({
        "web"     => "bin/rails server -p $PORT -e $RAILS_ENV",
        "console" => "bin/rails console"
      })
    end
  end

  def build_bundler
    instrument "rails4.build_bundler" do
      super
    end
  end

  def compile
    instrument "rails4.compile" do
      super
    end
  end

  private

  def install_plugins
    instrument "rails4.install_plugins" do
      return false if gem_is_bundled?('rails_12factor')
      plugins = ["rails_serve_static_assets", "rails_stdout_logging"].reject { |plugin| gem_is_bundled?(plugin) }
      return false if plugins.empty?

    warn <<-WARNING
Include 'rails_12factor' gem to enable all platform features
See https://devcenter.heroku.com/articles/rails-integration-gems for more information.
WARNING
    # do not install plugins, do not call super
    end
  end

  def public_assets_folder
    "public/assets"
  end

  def default_assets_cache
    "tmp/cache/assets"
  end

  def run_assets_precompile_rake_task
    instrument "rails4.run_assets_precompile_rake_task" do
      log("assets_precompile") do
        setup_database_url_env

        return true unless rake_task_defined?("assets:precompile")

        if Dir.glob('public/assets/manifest-*.json').any?
          puts "Detected manifest file, assuming assets were compiled locally"
          return true
        end

        topic("Preparing app for Rails asset pipeline")
        ENV["RAILS_GROUPS"] ||= "assets"
        ENV["RAILS_ENV"]    ||= "production"

        @cache.load public_assets_folder
        @cache.load default_assets_cache

        puts "Running: rake assets:precompile"
        require 'benchmark'
        time = Benchmark.realtime { pipe("env PATH=$PATH:bin bundle exec rake assets:precompile 2>&1 > /dev/null") }

        if $?.success?
          log "assets_precompile", :status => "success"
          puts "Asset precompilation completed (#{"%.2f" % time}s)"

          puts "Cleaning assets"
          pipe "env PATH=$PATH:bin bundle exec rake assets:clean 2>& 1"

          cleanup_assets_cache
          @cache.store public_assets_folder
          @cache.store default_assets_cache
        else
          log "assets_precompile", :status => "failure"
          error "Precompiling assets failed."
        end
      end
    end
  end

  def cleanup_assets_cache
    instrument "rails4.cleanup_assets_cache" do
      LanguagePack::Helpers::StaleFileCleaner.new(default_assets_cache).clean_over(ASSETS_CACHE_LIMIT)
    end
  end
end
