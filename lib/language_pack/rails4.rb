require "language_pack"
require "language_pack/rails3"

# Rails 4 Language Pack. This is for all Rails 4.x apps.
class LanguagePack::Rails4 < LanguagePack::Rails3
  # detects if this is a Rails 3.x app
  # @return [Boolean] true if it's a Rails 3.x app
  def self.use?
    if gemfile_lock?
      rails_version = LanguagePack::Ruby.gem_version('railties')
      rails_version >= Gem::Version.new('4.0.0.beta') && rails_version < Gem::Version.new('5.0.0') if rails_version
    end
  end

  def name
    "Ruby/Rails"
  end

  def default_process_types
    web_process = gem_is_bundled?("thin") ?
      "bin/rails server thin -p $PORT -e $RAILS_ENV" :
      "bin/rails server -p $PORT -e $RAILS_ENV"
    super.merge({
      "web"     => web_process,
      "console" => "bin/rails console"
    })
  end

  private
  def plugins
    []
  end

  def run_assets_precompile_rake_task
    log("assets_precompile") do
      setup_database_url_env

      if rake_task_defined?("assets:precompile")
        topic("Preparing app for Rails asset pipeline")
        if File.exists?("public/assets/manifest.yml")
          puts "Detected manifest.yml, assuming assets were compiled locally"
        else
          ENV["RAILS_GROUPS"] ||= "assets"
          ENV["RAILS_ENV"]    ||= "production"

          puts "Running: rake assets:precompile"
          require 'benchmark'
          time = Benchmark.realtime { pipe("env PATH=$PATH:bin bundle exec rake assets:precompile 2>&1") }

          if $?.success?
            log "assets_precompile", :status => "success"
            puts "Asset precompilation completed (#{"%.2f" % time}s)"
          else
            log "assets_precompile", :status => "failure"
            error "Precompiling assets failed."
          end
        end
      else
        puts "Error detecting the assets:precompile task"
      end
    end
  end

  def create_database_yml
  end
end
