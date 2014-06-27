DEPENDENCIES_PATH = File.expand_path("../../dependencies", File.expand_path($0))

if Dir.exist?(DEPENDENCIES_PATH)
  require 'language_pack/helpers/plugin_installer'

  module LanguagePack
    module Helpers
      class PluginsInstaller
        def vendor(name)
          directory = plugin_dir(name)
          return true if directory.exist?
          directory.mkpath
          Dir.chdir(directory) do |dir|
            dependency_filename = Extensions.translate(vendor_url, name)
            full_path = File.join(DEPENDENCIES_PATH, "#{dependency_filename}.tgz")
            run!("tar zxf #{full_path}")
          end
        end
      end
    end
  end
end