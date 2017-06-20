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
        ruby_vm = "ruby"
        file.sub!(ruby_vm, "#{ruby_vm}-build")
      end
      @fetcher.fetch_untar(file)
    end
  end

  def setup_binstubs(*)
    super
    Dir["#{DEFAULT_BIN_DIR}/{rake,bundle,rails}"].select do |binstub|
      begin
        if File.file?(binstub)
          shebang = File.open(binstub, &:readline)
          if !shebang.match %r{\A#!/usr/bin/env ruby(.exe)?\z}
            warn("Binstub #{binstub} contains shebang #{shebang}. This may cause issues if the program specified is unavailable.", inline: true)
          end
        end
      rescue EOFError
      end
    end
  end
end

