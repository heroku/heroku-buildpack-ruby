module LanguagePack
  module Helpers
    # Centralize logic for extracting information from the `Gemfile.lock` format
    #
    # - Extracts Ruby version from `RUBY VERSION`
    # - Extracts Bundler version from `BUNDLED WITH`
    #
    # Example:
    #
    #   gemfile_lock = GemfileLock.new(contents: <<~EOF)
    #     RUBY VERSION
    #        ruby 3.3.5p100
    #     BUNDLED WITH
    #        2.3.4
    #   EOF
    #
    #   expect(gemfile_lock.bundler.version).to eq("2.3.4")
    #   expect(gemfile_lock.ruby.ruby_version).to eq("3.3.5")
    class GemfileLock
      attr_reader :ruby, :bundler, :contents

      def initialize(contents: , report: HerokuBuildReport::GLOBAL)
        @ruby = RubyVersionParse.new(contents: contents, report: report)
        @bundler = BundlerVersionParse.new(contents: contents, report: report)
        @contents = contents
      end

      # Holds information about the RUBY VERSION of the parsed Gemfile.lock
      class RubyVersionParse
        # Ruby version from Gemfile.lock i.e. `3.3.8`
        # Either 3 numbers or nil
        attr_reader :ruby_version,
          # Contains pre-release info
          # - String: i.e. "rc2" is a prerelease
          # - nil: No pre-release (or no version at all)
          :pre,
          # Either :ruby or :jruby
          :engine,
          # `engine_version` is the JRuby version or for Ruby, it is the same as `ruby_version`
          # i.e. `<major>.<minor>.<patch>`
          :engine_version

        def initialize(contents: , report: HerokuBuildReport::GLOBAL)
          if match = contents.match(/^RUBY VERSION(\r?\n) {2,3}ruby (?<version>\d+\.\d+\.\d+)((\-|\.)(?<pre>\S*))?/m)
            @pre = match[:pre]
            @empty = false
            @ruby_version = match[:version]
          else
            if contents.match?(/RUBY VERSION/)
              report.capture("gemfile_lock.ruby_version.failed_parse" => true)
              if match = contents.match(/(?<contents>RUBY VERSION(\r?\n).*)$/)
                report.capture("gemfile_lock.ruby_version.failed_contents" => match[:contents])
              end
            end
            @pre = nil
            @empty = true
            @ruby_version = nil
          end

          if jruby = contents.to_s.match(/^RUBY VERSION(\r?\n) {2,3}ruby [^\(]*\(jruby (?<version>(\d+|\.)+)\)/m)
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

        def initialize(contents: , report: HerokuBuildReport::GLOBAL)
          if match = contents.match(/^BUNDLED WITH(\r?\n) {2,3}(?<version>(?<major>\d+)\.(?<minor>\d+)\.\d+)/m)
            @empty = false
            @version = match[:version]
          else
            if contents.match?(/BUNDLED WITH/)
              report.capture("gemfile_lock.bundler_version.failed_parse" => true)
              if match = contents.match(/(?<contents>BUNDLED WITH(\r?\n).*)$/)
                report.capture("gemfile_lock.bundler_version.failed_contents" => match[:contents])
              end
            end
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
