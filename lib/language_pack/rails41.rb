require 'securerandom'
require "language_pack"
require "language_pack/rails4"

class LanguagePack::Rails41 < LanguagePack::Rails4
  # detects if this is a Rails 4.x app
  # @return [Boolean] true if it's a Rails 4.x app
  def self.use?
    instrument "rails4.use" do
      rails_version = bundler.gem_version('railties')
      return false unless rails_version
      is_rails4 = rails_version >= Gem::Version.new('4.1.0.beta1') &&
                  rails_version <  Gem::Version.new('5.0.0')
      return is_rails4
    end
  end

  def create_database_yml
    instrument 'ruby.create_database_yml' do
    end
  end

  def setup_profiled
    instrument 'setup_profiled' do
      super
      set_env_default "SECRET_KEY_BASE", app_secret
    end
  end

  def default_config_vars
    super.merge({
      "SECRET_KEY_BASE" => app_secret
    })
  end

  private
  def app_secret
    key = "secret_key_base"

    @app_secret ||= begin
      if @metadata.exists?(key)
        @metadata.read(key).chomp
      else
        secret = SecureRandom.hex(64)
        @metadata.write(key, secret)

        secret
      end
    end
  end
end
