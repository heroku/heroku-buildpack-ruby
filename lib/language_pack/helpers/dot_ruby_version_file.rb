require "language_pack/shell_helpers"
require "language_pack/ruby_version"

module LanguagePack
  module Helpers
    # Parses contents of `.ruby-version` file to transform it into a RubyVersion
    #
    # Example:
    #
    #   version = DotRubyVersionFile.new(
    #     contents: File.read(".ruby-version")
    #   ).call
    #   assert_eq [], version.warnings
    #   assert_eq :ruby, version.ruby_version.engine
    class DotRubyVersionFile
      VERSION_PATTERN = /\A(?<version>\d+\.\d+\.\d+)(?:[.-](?<pre>\S+))?\z/
      JRUBY_PATTERN = /\Ajruby-/i
      SPECIFIER_PATTERN = /((>|<|~|=)+)/

      Result = Data.define(:ruby_version, :warnings)

      def initialize(contents:)
        @contents = contents
      end

      def call
        warnings = []
        lines = meaningful_lines

        if lines.empty?
          return Result.new(ruby_version: nil, warnings: warnings)
        end

        line = lines.first
        version_string = strip_ruby_prefix_and_at_suffix(line)

        if lines.length > 1
          warnings << <<~EOF
            The `.ruby-version` file contains multiple version lines.
            Only a single version is supported. Remove additional lines.

            Contents:

            ```
            #{@contents}
            ```
          EOF
        end

        if version_string.match?(JRUBY_PATTERN)
          warnings << <<~EOF
            JRuby not supported in `.ruby-version` file.

            The `.ruby-version` file contains a JRuby version however the
            JRuby engine is not supported by `.ruby-version` on Heroku at this time.

            Contents:

            ```
            #{@contents}
            ```
          EOF
        end

        if (match = version_string.match(SPECIFIER_PATTERN))
          specifier = match[1]
          warnings << <<~EOF
            Cannot parse `.ruby-version` file, version specifiers (`#{specifier}`) are not supported.

            Only exact versions are supported such as `3.4.8` or `ruby-3.4.8`.
            Got:

            ```
            #{@contents}
            ```
          EOF
        end

        if warnings.any?
          Result.new(ruby_version: nil, warnings: warnings)
        elsif (match = version_string.match(VERSION_PATTERN))
          Result.new(
            ruby_version: LanguagePack::RubyVersion.new(
              pre: match[:pre],
              engine: :ruby,
              default: false,
              ruby_version: match[:version],
              engine_version: match[:version]
            ),
            warnings: warnings
          )
        else
          warnings << <<~EOF
            Cannot parse Ruby version from `.ruby-version` file.

            Only full Ruby versions with major, minor, and patch are supported
            such as `3.4.8` or `ruby-3.4.8`. Got:

            ```
            #{@contents}
            ```
          EOF
          Result.new(ruby_version: nil, warnings: warnings)
        end
      end

      private def meaningful_lines
        @contents.gsub(/\s*#.*/, "").each_line.filter_map { |line|
          stripped = line.strip
          stripped unless stripped.empty?
        }
      end

      private def strip_ruby_prefix_and_at_suffix(line)
        version = line.delete_prefix("ruby-")
        version.split("@").first || ""
      end
    end
  end
end
