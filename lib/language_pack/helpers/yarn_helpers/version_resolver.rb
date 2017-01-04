require 'open-uri'
require 'uri'

module LanguagePack
  module Helpers
    module YarnHelpers
      class VersionResolver

        def resolve_node(provided_version)
          open("https://semver.herokuapp.com/node/resolve/#{provided_version}")
        end

        def resolve_yarn(provided_version)
          open("https://semver.herokuapp.com/yarn/resolve/#{provided_version}")
        end

        private

        def open uri
          super(URI.escape(uri)).read
        end
      end
    end
  end
end
