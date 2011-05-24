require "language_pack"
require "language_pack/rails2"

class LanguagePack::Rails3 < LanguagePack::Rails2

  def self.use?
    super &&
      File.exists?("config/application.rb") &&
      File.read("config/application.rb") =~ /Rails::Application/
  end

  def name
    "Rails"
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
  end

private

  def plugins
    super.concat(%w( rails3_serve_static_assets )).uniq
  end

end

