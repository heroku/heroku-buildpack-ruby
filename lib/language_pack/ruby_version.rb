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

    # `version`  is the raw input or default usually `ruby-<major>.<minor>.<patch>`
    attr_reader :version,
      # `version_without_patchlevel` is `version` with any trailing `-p<number>` stripped
      :version_without_patchlevel,
      # `ruby_version` is what `<major>.<minor>.<patch>`
      :ruby_version,
      # `engine` is either :ruby or :jruby
      :engine,
      # `engine_version` is the same as `ruby_version` for MRI and the JRuby version for jruby
      :engine_version,
      # `major.minor.patch` the digits of `ruby_version` in integers
      :major, :minor, :patch

    include LanguagePack::ShellHelpers

    def initialize(bundler_output, app = {})
      @bundler_output = bundler_output
      @app = app
      if @bundler_output.empty?
        @default = true
        @version = if @app[:is_new]
          DEFAULT_VERSION
        elsif @app[:last_version]
          @app[:last_version]
        else
          LEGACY_VERSION
        end
      else
        @default = false
        @version = @bundler_output
      end
      parsed = ParsedVersion.new(from_bundler: @version)
      @ruby_version = parsed.version
      @engine = parsed.engine
      @engine_version = parsed.engine_version
      @major = parsed.major
      @minor = parsed.minor
      @patch = parsed.patch

      @version_without_patchlevel = @version.sub(/-p-?\d+/, '')
    end

    def warn_ruby_26_bundler?
      return false if Gem::Version.new(self.ruby_version) >= Gem::Version.new("2.6.3")
      return false if Gem::Version.new(self.ruby_version) < Gem::Version.new("2.6.0")

      return true
    end

    # https://github.com/bundler/bundler/issues/4621
    def version_for_download
      version_without_patchlevel
    end

    def file_name
      "#{version_for_download}.tgz"
    end

    def rake_is_vendored?
      true
    end

    def default?
      @default
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

    # Returns the next logical version in the minor series
    # for example if the current ruby version is
    # `ruby-2.3.1` then then `next_logical_version(1)`
    # will produce `ruby-2.3.2`.
    def next_logical_version(increment = 1)
      "ruby-#{[major, minor, patch + increment].join(".")}"
    end

    def next_minor_version(increment = 1)
      "ruby-#{[major, minor + increment, 0].join(".")}"
    end

    def next_major_version(increment = 1)
      "ruby-#{[major + increment, 0, 0].join(".")}"
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
        @major = Integer(parts.shift)
        @minor = Integer(parts.shift)
        @patch = Integer(parts.shift)
      end
    end
  end
end
