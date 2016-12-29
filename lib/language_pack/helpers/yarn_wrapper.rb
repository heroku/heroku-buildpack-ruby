require 'json'
require 'open-uri'
require 'uri'
require_relative 'yarn_helpers/node_installer'
require_relative 'yarn_helpers/yarn_installer'

class LanguagePack::Helpers::YarnWrapper
  include LanguagePack::ShellHelpers

  VENDOR_DIR_PATH      = './vendor'

  def initialize
    vendor_dir_path =  ENV['VENDOR_DIR_PATH'] || VENDOR_DIR_PATH
    @vendor_path = Pathname.new(vendor_dir_path).realpath
  end

  def install_node_modules_and_dependencies
    FileUtils.chdir @vendor_path do
      if node_app?
        topic "yarn.lock file detected"
        node_installer.perform
        yarn_installer.perform
        install_packages
      end
    end
  end

  private

  def node_app?
    node_installer.yarn_lock_file && node_installer.package_file
  end

  def yarn_installer
    @yarn_installer ||= LanguagePack::Helpers::YarnHelpers::YarnInstaller.new
  end

  def node_installer
    @node_installer ||= LanguagePack::Helpers::YarnHelpers::NodeInstaller.new
  end

  def install_packages
    run! "../bin/yarn install"
  end

end
