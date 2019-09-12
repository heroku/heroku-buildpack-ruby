require 'securerandom'
require "language_pack"
require "language_pack/rails42"

class LanguagePack::Rails5 < LanguagePack::Rails42
  # @return [Boolean] true if it's a Rails 5.x app
  def self.use?
    instrument "rails5.use" do
      rails_version = bundler.gem_version('railties')
      return false unless rails_version
      is_rails = rails_version >= Gem::Version.new('5.x') &&
                 rails_version <  Gem::Version.new('6.0.0')
      return is_rails
    end
  end

  def setup_profiled
    instrument 'setup_profiled' do
      super
      set_env_default "RAILS_LOG_TO_STDOUT", "enabled"
    end
  end

  def default_config_vars
    super.merge({
      "RAILS_LOG_TO_STDOUT" => "enabled"
    })
  end

  def install_plugins
    # do not install plugins, do not call super, do not warn
  end

  def config_detect
    super
    @local_storage_config = @rails_runner.detect("active_storage.service")
  end

  def best_practice_warnings
    super
    return unless bundler.has_gem?("activestorage")
    return unless File.exist?("config/storage.yml")

    warn_local_storage if local_storage?
    warn_no_ffmpeg     if needs_ffmpeg?
  end

  private
    def has_ffmpeg?
      run("which ffmpeg")
      return $?.success?
    end

    def needs_ffmpeg?
      !has_ffmpeg?
    end

    def local_storage?
      return false unless @local_storage_config.success?
      @local_storage_config.did_match?("local")
    end

    def warn_local_storage
      mcount("warn.activestorage.local_storage")
      warn(<<-WARNING)
You set your `config.active_storage.service` to :local in production.
If you are uploading files to this app, they will not persist after the app
is restarted, on one-off dynos, or if the app has multiple dynos.
Heroku applications have an ephemeral file system. To
persist uploaded files, please use a service such as S3 and update your Rails
configuration.

For more information can be found in this article:
  https://devcenter.heroku.com/articles/active-storage-on-heroku

WARNING
    end

    def warn_no_ffmpeg
      mcount("warn.activestorage.no_binaries.stack-#{stack}")
      mcount("warn.activestorage.no_binaries.all")
      warn(<<-WARNING)
We detected that some binary dependencies required to
use all the preview features of Active Storage are not
present on this system.

For more information please see:
  https://devcenter.heroku.com/articles/active-storage-on-heroku

WARNING
    end
end
