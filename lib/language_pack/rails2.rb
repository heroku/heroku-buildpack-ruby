require "fileutils"
require "language_pack"
require "language_pack/rack"

class LanguagePack::Rails2 < LanguagePack::Ruby

  def self.use?
    super && File.exist?("config/environment.rb")
  end

  def name
    "Rails"
  end

  def default_config_vars
    super.merge({
      "RAILS_ENV" => "production",
      "RACK_ENV" => "production"
    })
  end

  def default_process_types
    web_process = gem_is_bundled?("thin") ?
                    "bundle exec thin start -e $RAILS_ENV -p $PORT" :
                    "bundle exec ruby script/server -p $PORT"

    super.merge({
      "web" => web_process,
      "worker" => "bundle exec rake jobs:work",
      "console" => "bundle exec script/console"
    })
  end

  def default_addons
    %w( shared-database:5mb )
  end

  def compile
    super
    install_plugins
  end

private

  def plugins
    %w( rails_log_stdout )
  end

  def plugin_root
    File.expand_path("../../../vendor/plugins", __FILE__)
  end

  def install_plugins
    topic "Rails plugin injection"
    plugins.each { |plugin| install_plugin(plugin) }
  end

  def install_plugin(name)
    return if File.exist?("vendor/plugins/#{name}")
    puts "Injecting #{name}"
    FileUtils.mkdir_p "vendor/plugins"
    FileUtils.cp_r File.join(plugin_root, name), "vendor/plugins"
  end

end

