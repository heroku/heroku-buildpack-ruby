require 'language_pack/installers/ruby_installer'
require 'language_pack/base'
require 'language_pack/shell_helpers'
require 'forwardable'

class LanguagePack::Installers::HerokuRubyInstaller
  extend Forwardable
  include LanguagePack::ShellHelpers, LanguagePack::Installers::RubyInstaller

  BASE_URL = LanguagePack::Base::VENDOR_URL

  delegate :'cache=' => :@fetcher

  def initialize(stack)
    @fetcher = LanguagePack::Fetcher.new(BASE_URL, stack)
  end

  def fetch_unpack(ruby_version, install_dir, build = false)
    FileUtils.mkdir_p(install_dir)
    Dir.chdir(install_dir) do
      file = "#{ruby_version.version_for_download}.tgz"
      if build
        ruby_vm = "ruby"
        file.sub!(ruby_vm, "#{ruby_vm}-build")
      end
      @fetcher.fetch_untar(file)
    end
  end
end
