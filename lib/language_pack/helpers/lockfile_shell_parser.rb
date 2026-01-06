# frozen_string_literal: true

require "json"

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
      extend LanguagePack::ShellHelpers

      RUBY_PARSER_CODE = <<~RUBY
        require "json"
        require "bundler"

        path = ARGV[0] or raise "First argument must be the path to the Gemfile.lock"
        specs = Bundler::LockfileParser.new(File.read(path))
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
        output = run!("ruby -e #{RUBY_PARSER_CODE.shellescape} #{lockfile_path.to_s.shellescape}", out: "2>/dev/null")
        JSON.parse(output).transform_values { |version| Gem::Version.new(version) }
      end
    end
  end
end

