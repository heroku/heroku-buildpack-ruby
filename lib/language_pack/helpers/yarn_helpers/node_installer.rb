require_relative 'yarn_config_helper'
require_relative 'version_resolver'

module LanguagePack
  module Helpers
    module YarnHelpers
      class NodeInstaller
        include YarnConfigHelper
        include LanguagePack::ShellHelpers

        def initialize
          @node_fetcher = LanguagePack::Fetcher.new("https://nodejs.org/dist/")
        end

        def perform
          topic "installing #{binary_name}"
          @node_fetcher.fetch_untar(binary_path, "#{binary_name}/bin")
          FileUtils.cp_r("#{binary_name}/.", "./node")
          FileUtils.rm_rf(binary_name)
        end

        private

        def version
          @version ||= VersionResolver.new.resolve_node(node_version)
        end

        def binary_name
          @binary_name ||= "node-v#{version}-linux-x64"
        end

        def binary_path
          "v#{version}/#{binary_name}.tar.gz"
        end
      end
    end
  end
end
