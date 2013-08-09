require "language_pack"
require "language_pack/rails2"

# Rails 3 Language Pack. This is for all Rails 3.x apps.
class LanguagePack::Rails3 < LanguagePack::Rails2
  PLUGINS = ["rails_log_stdout", "rails3_serve_static_assets"]
  # detects if this is a Rails 3.x app
  # @return [Boolean] true if it's a Rails 3.x app
  def self.use?
    instrument "rails3.use" do
      if gemfile_lock?
        rails_version = LanguagePack::Ruby.gem_version('railties')
        rails_version >= Gem::Version.new('3.0.0') && rails_version < Gem::Version.new('4.0.0') if rails_version
      end
    end
  end

  def name
    "Ruby/Rails"
  end

  def default_process_types
    instrument "rails3.default_process_types" do
      # let's special case thin here
      web_process = gem_is_bundled?("thin") ?
        "bundle exec thin start -R config.ru -e $RAILS_ENV -p $PORT" :
        "bundle exec rails server -p $PORT"

      super.merge({
        "web" => web_process,
        "console" => "bundle exec rails console"
      })
    end
  end

  def compile
    instrument "rails3.compile" do
      super
    end
  end

private

  def install_plugins
    return false unless plugins.any?
    plugins.each do |name|
      warn "Injecting plugin '#{name}', to skip add 'rails_12factor' gem to your Gemfile"
    end
    super
  end

  # runs the tasks for the Rails 3.1 asset pipeline
  def run_assets_precompile_rake_task
    instrument "rails3.run_assets_precompile_rake_task" do
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
              puts "Precompiling assets failed, enabling runtime asset compilation"
              install_plugin("rails31_enable_runtime_asset_compilation")
              puts "Please see this article for troubleshooting help:"
              puts "http://devcenter.heroku.com/articles/rails31_heroku_cedar#troubleshooting"
            end
          end
        end
      end
    end
  end

  # setup the database url as an environment variable
  def setup_database_url_env
    instrument "rails3.setup_database_url_env" do
      ENV["DATABASE_URL"] ||= begin
        # need to use a dummy DATABASE_URL here, so rails can load the environment
        scheme =
          if gem_is_bundled?("pg") || gem_is_bundled?("jdbc-postgres")
            "postgres"
          elsif gem_is_bundled?("mysql")
            "mysql"
          elsif gem_is_bundled?("mysql2")
            "mysql2"
          elsif gem_is_bundled?("sqlite3") || gem_is_bundled?("sqlite3-ruby")
            "sqlite3"
          end
        "#{scheme}://user:pass@127.0.0.1/dbname"
      end
    end
  end
end
