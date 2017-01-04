require 'json'

module LanguagePack
  module Helpers
    module YarnHelpers
      module YarnConfigHelper
        def parsed_package_file
          @parsed_package_file ||= begin
            json = File.read(package_file)
            JSON.parse(json)
          end
        end

        def engine_config
          @engine_config ||= parsed_package_file.fetch('engines', {})
        end

        def node_version
          engine_config['node']
        end

        def yarn_version
          engine_config['yarn']
        end

        def yarn_lock_file
          Dir["yarn.lock"].first
        end

        def package_file
          Dir["package.json"].first
        end
      end
    end
  end
end
