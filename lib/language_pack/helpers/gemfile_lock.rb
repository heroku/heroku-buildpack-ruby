require "language_pack/shell_helpers"

module LanguagePack
  module Helpers
    # Centralize logic for extracting information from the `Gemfile.lock` format
    #
    # - Extracts Ruby version from `RUBY VERSION`
    # - Extracts Bundler version from `BUNDLED WITH`
    class GemfileLock
      attr_reader :ruby, :bundler

      def initialize(contents: )
        @ruby = RubyVersionParse.new(contents: contents)
        @bundler = BundlerVersionParse.new(contents: contents)
      end

      # Holds information about the RUBY VERSION of the parsed Gemfile.lock
      class RubyVersionParse
        # Ruby version from Gemfile.lock i.e. `3.3.8`
        # Either 3 numbers or nil
        attr_reader :ruby_version,
          # Contains pre-release info
          # - String: i.e. ".rc2" is a prerelease
          # - nil: No pre-release (or no version at all)
          :pre,
          # Either :ruby or :jruby
          :engine,
          # `engine_version` is the JRuby version or for Ruby it is the same as `ruby_version`
          # i.e. `<major>.<minor>.<patch>`
          :engine_version

        def initialize(contents: )

          if match = contents.match(/^RUBY VERSION(\r?\n)   ruby (?<version>\d+\.\d+\.\d+)((\-|\.)(?<pre>\S*\d+))?/m)
            @pre = match[:pre]
            @empty = false
            @ruby_version = match[:version]
          else
            @pre = nil
            @empty = true
            @ruby_version = nil
          end

          if jruby = contents.to_s.match(/\(jruby (?<version>(\d+|\.)+)\)/)
            @engine = :jruby
            @engine_version = jruby[:version]
          else
            @engine = :ruby
            @engine_version = ruby_version
          end
        end

        def empty?
          @empty
        end
      end

      class BundlerVersionParse
        # Bundler value from `Gemfile.lock` (String or nil) i.e. `2.5.23`
        attr_reader :version

        def initialize(contents: )
          if match = contents.match(/^BUNDLED WITH$(\r?\n)   (?<version>(?<major>\d+)\.(?<minor>\d+)\.\d+)/m)
            @empty = false
            @version = match[:version]
          else
            @empty = true
            @version = nil
          end
        end

        def empty?
          @empty
        end
      end
    end
  end
end
