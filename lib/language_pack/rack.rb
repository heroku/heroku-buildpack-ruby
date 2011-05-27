require "language_pack"
require "language_pack/ruby"

class LanguagePack::Rack < LanguagePack::Ruby

  def self.use?
    super && File.exist?("config.ru")
  end

  def name
    "Ruby/Rack"
  end

  def default_config_vars
    super.merge({
      "RACK_ENV" => "production"
    })
  end

  def default_process_types
    web_process = gem_is_bundled?("thin") ?
                    "bundle exec thin start -R config.ru -p $PORT" :
                    "bundle exec rackup config.ru -p $PORT"

    super.merge({
      "web" => web_process
    })
  end

end

