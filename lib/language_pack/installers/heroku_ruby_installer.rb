require 'language_pack/base'
require 'language_pack/shell_helpers'
require 'heroku_build_report'

module LanguagePack::Installers; end

class LanguagePack::Installers::HerokuRubyInstaller
  BASE_URL = LanguagePack::Base::VENDOR_URL
  BIN_DIR = Pathname("bin")

  include LanguagePack::ShellHelpers
  attr_reader :fetcher

  def initialize(stack: , multi_arch_stacks: , arch: , report: HerokuBuildReport::GLOBAL)
    @report = report
    if multi_arch_stacks.include?(stack)
      @fetcher = LanguagePack::Fetcher.new(BASE_URL, stack: stack, arch: arch)
    else
      @fetcher = LanguagePack::Fetcher.new(BASE_URL, stack: stack)
    end
  end

  def install(ruby_version, install_dir)
    @report.capture("ruby_version" => ruby_version.version)
    fetch_unpack(ruby_version, install_dir)
    setup_binstubs(install_dir)
  end

  def fetch_unpack(ruby_version, install_dir)
    FileUtils.mkdir_p(install_dir)
    Dir.chdir(install_dir) do
      @fetcher.fetch_untar("#{ruby_version.version_for_download}.tgz")
    end
  end

  private def setup_binstubs(install_dir)
    BIN_DIR.mkpath
    run("ln -s ruby #{install_dir}/bin/ruby.exe")

    install_pathname = Pathname.new(install_dir)
    Dir["#{install_dir}/bin/*"].each do |vendor_bin|
      # for Ruby 2.6.0+ don't symlink the Bundler bin so our shim works
      next if vendor_bin.include?("bundle")

      # The bin/rake binstub generated when compiling ruby does not load bundler
      # which can cause unexpected failures. Deleting this binstub allows two things:
      #
      #   - If the app includes a custom binstub allows it to be used
      #   - If the app does not include a custom binstub, then it will fall back to vendor/bundle/bin/rake
      #     which is generated by bundler
      #
      # Discussion: https://github.com/heroku/heroku-buildpack-ruby/issues/1025#issuecomment-653102430
      next if vendor_bin.include?("rake")

      if install_pathname.absolute?
        run("ln -s #{vendor_bin} #{BIN_DIR}")
      else
        run("ln -s ../#{vendor_bin} #{BIN_DIR}")
      end
    end
  end
end
