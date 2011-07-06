require "language_pack"
require "language_pack/rails2"

class LanguagePack::Rails3 < LanguagePack::Rails2

  JS_RUNTIME_PATH = File.expand_path(File.join(File.dirname(__FILE__), '../../vendor/node/node-0.4.7'))

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
    run_assets_precompile_task
  end

private

  def plugins
    super.concat(%w( rails3_serve_static_assets )).uniq
  end

  def run_assets_precompile_task
    if rake_task_defined?("assets:precompile") && !rake_task_defined?("compile")
      topic("Running assets:precompile task")
      # need to use a dummy DATABASE_URL here, so rails can load the environment
      pipe("env DATABASE_URL=postgres://user:pass@127.0.0.1/dbname PATH=$PATH:#{JS_RUNTIME_PATH} bundle exec rake assets:precompile 2>&1")
      unless $?.success?
        error "assets:precompile task failed"
      end
    end
  end

end

