require "language_pack/shell_helpers"

module LanguagePack
  class RubyVersion
    class BadVersionError < BuildpackError
      def initialize(output = "")
        super <<~EOL
          Cannot parse Ruby version: #{output}

          Valid versions:
            https://devcenter.heroku.com/articles/ruby-support-reference
        EOL
      end
    end

    BOOTSTRAP_VERSION_NUMBER = "3.1.6".freeze
    DEFAULT_VERSION_NUMBER = "3.3.7".freeze
    DEFAULT_VERSION        = "ruby-#{DEFAULT_VERSION_NUMBER}".freeze
    LEGACY_VERSION_NUMBER  = "1.9.2".freeze
    LEGACY_VERSION         = "ruby-#{LEGACY_VERSION_NUMBER}".freeze
    RUBY_VERSION_REGEX     = %r{
        (?<ruby_version>\d+\.\d+\.\d+){0}
        (?<patchlevel>p-?\d+){0}
        (?<engine>\w+){0}
        (?<engine_version>.+){0}

        ruby-\g<ruby_version>(-\g<patchlevel>)?(-\g<engine>-\g<engine_version>)?
      }x

    attr_reader :set, :version, :version_without_patchlevel, :engine, :ruby_version, :engine_version
    include LanguagePack::ShellHelpers

    def initialize(bundler_output, app = {})
      @set            = nil
      @bundler_output = bundler_output
      @app            = app
      if @bundler_output.empty?
        @set     = false
        @version = none
      else
        @set     = :gemfile
        @version = @bundler_output
      end
      parse_version

      @version_without_patchlevel = @version.sub(/-p-?\d+/, '')
    end

    def warn_ruby_26_bundler?
      return false if Gem::Version.new(self.ruby_version) >= Gem::Version.new("2.6.3")
      return false if Gem::Version.new(self.ruby_version) < Gem::Version.new("2.6.0")

      return true
    end

    def ruby_192_or_lower?
      Gem::Version.new(self.ruby_version) <= Gem::Version.new("1.9.2")
    end

    # https://github.com/bundler/bundler/issues/4621
    def version_for_download
      version_without_patchlevel
    end

    def file_name
      "#{version_for_download}.tgz"
    end

    def rake_is_vendored?
      Gem::Version.new(self.ruby_version) >= Gem::Version.new("1.9")
    end

    def default?
      @version == none
    end

    # determine if we're using jruby
    # @return [Boolean] true if we are and false if we aren't
    def jruby?
      engine == :jruby
    end

    # convert to a Gemfile ruby DSL incantation
    # @return [String] the string representation of the Gemfile ruby DSL
    def to_gemfile
      if @engine == :ruby
        "ruby '#{ruby_version}'"
      else
        "ruby '#{ruby_version}', :engine => '#{engine}', :engine_version => '#{engine_version}'"
      end
    end

    # does this vendor bundler
    def vendored_bundler?
      false
    end

    def major
      @version_without_patchlevel.split(".")[0].gsub(/ruby-/, "").to_i
    end

    def minor
      @version_without_patchlevel.split(".")[1].to_i
    end

    def patch
      @version_without_patchlevel.split(".")[2].to_i
    end

    # Returns the next logical version in the minor series
    # for example if the current ruby version is
    # `ruby-2.3.1` then then `next_logical_version(1)`
    # will produce `ruby-2.3.2`.
    def next_logical_version(increment = 1)
      split_version = @version_without_patchlevel.split(".")
      teeny = split_version.pop
      split_version << teeny.to_i + increment
      split_version.join(".")
    end

    def next_minor_version(increment = 1)
      split_version = @version_without_patchlevel.split(".")
      split_version[1] = split_version[1].to_i + increment
      split_version[2] = 0
      split_version.join(".")
    end

    def next_major_version(increment = 1)
      split_version = @version_without_patchlevel.split("-").last.split(".")
      split_version[0] = Integer(split_version[0]) + increment
      split_version[1] = 0
      split_version[2] = 0
      return "ruby-#{split_version.join(".")}"
    end

    private

    def none
      if @app[:is_new]
        DEFAULT_VERSION
      elsif @app[:last_version]
        @app[:last_version]
      else
        LEGACY_VERSION
      end
    end

    class ParsedVersion
      attr_reader :version, :major, :minor, :patch, :engine, :engine_version

      # Input is the raw string from bundler like `ruby-3.1.4`
      def initialize(from_bundler: )
        @raw = from_bundler
        match = RUBY_VERSION_REGEX.match(@raw)
        raise BadVersionError.new("'#{version}' is not valid") unless match

        @version = match[:ruby_version] # like "3.1.4"
        if match[:engine]
          @engine = match[:engine].to_sym
          @engine_version = match[:engine_version]
        else
          @engine = :ruby
          @engine_version = @version
        end
        parts = @version.split(".")
        @major = parts.shift
        @minor = parts.shift
        @patch = parts.shift
      end
    end

    def parse_version
      md = RUBY_VERSION_REGEX.match(version)
      raise BadVersionError.new("'#{version}' is not valid") unless md
      @ruby_version   = md[:ruby_version]
      @engine_version = md[:engine_version] || @ruby_version
      @engine         = (md[:engine]        || :ruby).to_sym
    end
  end
end
