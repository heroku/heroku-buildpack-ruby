# frozen_string_literal: true

require "json"
require "tempfile"
require "open3"

module LanguagePack
  module Helpers
    # Parses gem specs from a Gemfile.lock file using Bundler::LockfileParser.
    #
    # This module encapsulates the logic for extracting gem names and versions
    # from a lockfile, running the parsing in a subprocess to avoid polluting
    # the current process's Bundler state.
    #
    # This can be called before gems are installed (but after Ruby and Bundler are installed).
    # The output of this and `bundle list` (which can only be invoked after gems are installed)
    # will disagree based on env vars such as `BUNDLE_WITHOUT`.
    #
    # This output will usually be a superset of `bundle list` output.
    #
    # Example:
    #
    #   specs = LockfileShellParser.call(lockfile_path: "/path/to/Gemfile.lock")
    #   specs["rake"] # => #<Gem::Version "13.2.1">
    #
    module LockfileShellParser
      RUBY_PARSER_CODE = <<~RUBY
        require "json"
        require "bundler"

        specs = Bundler::LockfileParser.new(STDIN.read)
          .specs
          .each_with_object({}) {|spec, hash| hash[spec.name.to_s] = spec.version.to_s }
        puts specs.to_json
      RUBY

      # Parses gem specs from a Gemfile.lock file path.
      #
      # @param lockfile_path [String, Pathname] Path to the Gemfile.lock file
      # @return [Hash{String => Gem::Version}] Hash of gem names to their versions
      #
      # Example:
      #
      #   specs = LockfileShellParser.call(lockfile_path: "Gemfile.lock")
      #   specs["rails"]    # => #<Gem::Version "7.0.4">
      #   specs["nokogiri"] # => #<Gem::Version "1.15.0">
      #
      def self.call(lockfile_path:)
        lockfile_path = Pathname(lockfile_path)
        Tempfile.create(['lockfile_parser', '.rb']) do |tempfile|
          tempfile.write(RUBY_PARSER_CODE)
          tempfile.flush

          stdout, stderr, status = Open3.capture3("ruby", tempfile.path, stdin_data: lockfile_path.read(mode: "rt"))
          if status.success?
            JSON.parse(stdout).transform_values { |version| Gem::Version.new(version) }
          else
            raise <<~ERROR
              Cannot parse `Gemfile.lock` file at path `#{lockfile_path}`

              The Ruby buildpack runs a Ruby script that uses Bundler::LockfileParser to parse the lockfile of your application.
              This information is needed to set environment variables based on requested gems such as `RAILS_ENV`
              before gems are installed via `bundle install`.

              This script failed to parse `#{lockfile_path}` and the buildpack cannot continue.

              Debugging information:

              status: #{status}
              stdout: #{stdout}
              stderr: #{stderr}
            ERROR
          end
        end
      end
    end
  end
end

