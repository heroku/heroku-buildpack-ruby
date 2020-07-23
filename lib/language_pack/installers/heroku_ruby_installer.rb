require 'language_pack/installers/ruby_installer'
require 'language_pack/base'
require 'language_pack/shell_helpers'

class LanguagePack::Installers::HerokuRubyInstaller
  include LanguagePack::ShellHelpers, LanguagePack::Installers::RubyInstaller

  BASE_URL = LanguagePack::Base::VENDOR_URL

  def initialize(stack)
    @fetcher = LanguagePack::Fetcher.new(BASE_URL, stack)
  end

  def fetch_unpack(ruby_version, install_dir, build = false)
    FileUtils.mkdir_p(install_dir)
    Dir.chdir(install_dir) do
      file = "#{ruby_version.version_for_download}.tgz"
      if build
        file.sub!("ruby", "ruby-build")
      end
      if ruby_override = user_env_hash['HEROKU_RUBY_BINARY_OVERRIDE']
        warn "Using Unsupported Ruby Binary Override: #{ruby_override}"
      end
      @fetcher.fetch_untar(file, {source_override: ruby_override})
    end
  end
end

