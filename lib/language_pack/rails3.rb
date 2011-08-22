require "language_pack"
require "language_pack/rails2"

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
    allow_git { run_assets_precompile_task }
  end

private

  def plugins
    super.concat(%w( rails3_serve_static_assets )).uniq
  end

  def binaries
    node = gem_is_bundled?('execjs') ? [NODE_JS_BINARY_PATH] : []
    super + node
  end

  def run_assets_precompile_task
    if rake_task_defined?("assets:precompile")
      topic("Preparing app for Rails asset pipeline")
      run("mkdir -p tmp/cache")
      # need to use a dummy DATABASE_URL here, so rails can load the environment
      run("env RAILS_ENV=production DATABASE_URL=postgres://user:pass@127.0.0.1/dbname PATH=$PATH:bin bundle exec rake assets:precompile 2>&1")
      if $?.success?
        # uninstall_binary(NODE_JS_BINARY_PATH)
      end
    end
  end

end

