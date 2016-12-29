require_relative 'yarn_config_helper'
require_relative 'version_resolver'

module LanguagePack
  module Helpers
    module YarnHelpers
      class YarnInstaller
        include YarnConfigHelper
        include LanguagePack::ShellHelpers

        def initialize
          @yarn_fetcher = LanguagePack::Fetcher.new("https://yarnpkg.com/downloads/")
        end

        def perform
          topic "installing yarn v#{version}"
          @yarn_fetcher.fetch_untar(binary_path, "dist/")
          FileUtils.cp_r("dist/.", "./yarn")
          FileUtils.rm_rf("dist")
        end

        private

        def version
          @version ||= VersionResolver.new.resolve_yarn(yarn_version)
        end

        def binary_path
          "#{version}/yarn-v#{version}.tar.gz"
        end

      end
    end
  end
end
