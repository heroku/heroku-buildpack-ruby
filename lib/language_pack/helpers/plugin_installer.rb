require "language_pack/shell_helpers"

module LanguagePack
  module Helpers
    # Takes an array of plugin names and vendor_url
    # fetches plugins from url, installs them
    class PluginsInstaller
      attr_accessor :plugins, :vendor_url
      include LanguagePack::ShellHelpers

      def initialize(plugins, vendor_url = LanguagePack::Base::VENDOR_URL)
        @plugins    = plugins || []
        @vendor_url = vendor_url
      end

      # vendors all the plugins into the slug
      def install
        return true unless plugins.any?
        plugins.each { |plugin| vendor(plugin) }
      end

      def plugin_dir(name = "")
        Pathname.new("vendor/plugins").join(name)
      end

      # vendors an individual plugin
      # @param [String] name of the plugin
      def vendor(name)
        directory = plugin_dir(name)
        return true if directory.exist?
        directory.mkpath
        Dir.chdir(directory) do |dir|
          run("curl #{vendor_url}/#{name}.tgz -s -o - | tar xzf -")
        end
      end
    end
  end
end
