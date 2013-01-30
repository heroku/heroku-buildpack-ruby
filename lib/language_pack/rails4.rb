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

  def run_assets_precompile_rake_task
    log("assets_precompile") do
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
            puts "Precompiling assets failed."
            puts "Please see this article for troubleshooting help:"
            puts "http://devcenter.heroku.com/articles/rails31_heroku_cedar#troubleshooting"
          end
        end
      else
        puts "Error detecting the assets:precompile task"
      end
    end
  end
end
