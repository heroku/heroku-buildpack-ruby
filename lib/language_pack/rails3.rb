require "language_pack"
require "language_pack/rails2"

# Rails 3 Language Pack. This is for all Rails 3.x apps.
class LanguagePack::Rails3 < LanguagePack::Rails2
  # detects if this is a Rails 3.x app
  # @return [Boolean] true if it's a Rails 3.x app
  def self.use?
    super &&
      File.exists?("config/application.rb") &&
      File.read("config/application.rb") =~ /Rails::Application/
  end

  def name
    "Ruby/Rails"
  end

  def default_process_types
    # let's special case thin here
    web_process = gem_is_bundled?("thin") ?
                    "bundle exec thin start -R config.ru -e $RAILS_ENV -p $PORT" :
                    "bundle exec rails server -p $PORT"

    super.merge({
      "web" => web_process,
      "console" => "bundle exec rails console"
    })
  end

private

  def plugins
    super.concat(%w( rails3_serve_static_assets )).uniq
  end

  # runs the tasks for the Rails 3.1 asset pipeline
  def run_assets_precompile_rake_task
    log("assets_precompile") do
      setup_database_url_env

      if rake_task_defined?("assets:precompile")
        topic("Preparing app for Rails asset pipeline")
        if File.exists?("public/assets/manifest.yml")
          puts "Detected manifest.yml, assuming assets were compiled locally"
        else
          FileUtils.mkdir_p('public')
          cache_load "public/assets"
          update_mtimes_for_current_assets

          ENV["RAILS_GROUPS"] ||= "assets"
          ENV["RAILS_ENV"]    ||= "production"

          puts "Running: rake assets:precompile"
          require 'benchmark'
          time = Benchmark.realtime { pipe("env PATH=$PATH:bin bundle exec rake assets:precompile 2>&1") }

          if $?.success?
            log "assets_precompile", :status => "success"
            puts "Asset precompilation completed (#{"%.2f" % time}s)"

            remove_expired_assets
            cache_store "public/assets"
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

  # Updates the mtimes for current assets, which marks the time when they were last deployed.
  # This is done so that old assets are expired correctly, based on their mtime.
  def update_mtimes_for_current_assets
    return false unless File.exists?("public/assets/manifest.yml")

    digests = YAML.load_file("public/assets/manifest.yml")
    # Iterate over all assets, including gzipped versions
    digests.flatten.flat_map {|a| [a, "#{a}.gz"] }.each do |asset|
      rel_path = File.join('public/assets', asset)
      File.utime(Time.now, Time.now, rel_path) if File.exist?(rel_path)
    end
  end

  # Removes assets that haven't been in use for a given period of time (defaults to 1 week.)
  # The expiry time can be configured by setting the env variable EXPIRE_ASSETS_AFTER,
  # which is the number of seconds to keep unused assets.
  def remove_expired_assets
    expire_after = (ENV["EXPIRE_ASSETS_AFTER"] || (3600 * 24 * 7)).to_i

    Dir.glob('public/assets/**/*').each do |asset|
      next if File.directory?(asset)
      # Remove asset if older than expire_after time
      if File.mtime(asset) < (Time.now - expire_after)
        puts "Removing expired asset: #{asset.sub(%r{.*/public/assets/}, '')}"
        FileUtils.rm_f asset
      end
    end
  end

  # setup the database url as an environment variable
  def setup_database_url_env
    ENV["DATABASE_URL"] ||= begin
      # need to use a dummy DATABASE_URL here, so rails can load the environment
      scheme =
        if gem_is_bundled?("pg")
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
