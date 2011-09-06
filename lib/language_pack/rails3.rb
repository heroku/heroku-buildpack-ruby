require "language_pack"
require "language_pack/rails2"
require "digest/md5"

class LanguagePack::Rails3 < LanguagePack::Rails2
  NODE_JS_BINARY_PATH = 'node-0.4.7/node'

  def self.use?
    super &&
      File.exists?("config/application.rb") &&
      File.read("config/application.rb") =~ /Rails::Application/
  end

  def name
    "Ruby/Rails"
  end

  def default_process_types
    web_process = gem_is_bundled?("thin") ?
                    "bundle exec thin start -R config.ru -e $RAILS_ENV -p $PORT" :
                    "bundle exec rails server -p $PORT"

    super.merge({
      "web" => web_process,
      "console" => "bundle exec rails console"
    })
  end

  def compile
    super
    allow_git { setup_asset_pipeline }
  end

private

  def plugins
    super.concat(%w( rails3_serve_static_assets )).uniq
  end

  def binaries
    node = gem_is_bundled?('execjs') ? [NODE_JS_BINARY_PATH] : []
    super + node
  end

  def setup_asset_pipeline
    if rake_task_defined?("assets:precompile")
      topic("Preparing app for Rails asset pipeline")
      if File.exists?("public/assets/manifest.yml")
        puts "Detected manifest.yml, assuming assets were compiled locally"
      else
        puts "Running: rake assets:precompile"
        rake_output = ""
        without_database_yml do
          rake_output << run("env RAILS_ENV=production RAILS_GROUPS=assets PATH=$PATH:bin bundle exec rake assets:precompile 2>&1")
        end

        puts rake_output
        unless $?.success?
          puts "Precompiling assets failed, enabling runtime asset compilation"
          install_plugin("rails31_enable_runtime_asset_compilation")
          # uninstall_binary(NODE_JS_BINARY_PATH)
        end
      end
    end
  end

  def without_database_yml
    digest           = Digest::MD5.hexdigest(Time.now.to_s)
    destination_file = "database-#{digest}.yml"

    run("mv config/database.yml tmp/#{destination_file}")
    yield
    run("mv tmp/#{destination_file} config/database.yml")
  end
end
