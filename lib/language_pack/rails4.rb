require "language_pack"
require "language_pack/rails3"

# Rails 4 Language Pack. This is for all Rails 4.x apps.
class LanguagePack::Rails4 < LanguagePack::Rails3
  # detects if this is a Rails 3.x app
  # @return [Boolean] true if it's a Rails 3.x app
  def self.use?
    instrument "rails4.use" do
      if gemfile_lock?
        rails_version = LanguagePack::Ruby.gem_version('railties')
        rails_version >= Gem::Version.new('4.0.0.beta') && rails_version < Gem::Version.new('5.0.0') if rails_version
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
      check_for_rails_gems
    end
  end

  def compile
    instrument "rails4.compile" do
      super
    end
  end

  private
  def rails_gems
    %w(rails_stdout_logging rails_serve_static_assets)
  end

  def check_for_rails_gems
    instrument "rails4.check_for_rails_gems" do
      if rails_gems.any? {|gem| !gem_is_bundled?(gem) }
        warn(<<WARNING)
Include "rails_12factor" gem to enable all platform features
See https://devcenter.heroku.com/articles/rails-integration-gems for more information.
WARNING
      end
    end
  end

  def plugins
    []
  end

  def public_assets_folder
    "public/assets"
  end

  def run_assets_precompile_rake_task
    instrument "rails4.run_assets_precompile_rake_task" do
      log("assets_precompile") do
        setup_database_url_env

        if rake_task_defined?("assets:precompile")
          topic("Preparing app for Rails asset pipeline")
          if Dir.glob('public/assets/manifest-*.json').any?
            puts "Detected manifest file, assuming assets were compiled locally"
          else
            ENV["RAILS_GROUPS"] ||= "assets"
            ENV["RAILS_ENV"]    ||= "production"

            @cache.load public_assets_folder

            puts "Running: rake assets:precompile"
            require 'benchmark'
            time = Benchmark.realtime { pipe("env PATH=$PATH:bin bundle exec rake assets:precompile 2>&1 > /dev/null") }

            if $?.success?
              log "assets_precompile", :status => "success"
              puts "Asset precompilation completed (#{"%.2f" % time}s)"

              puts "Cleaning assets"
              pipe "env PATH=$PATH:bin bundle exec rake assets:clean 2>& 1"

              @cache.store public_assets_folder
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
  end
end
