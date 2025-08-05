require "language_pack/shell_helpers" # Holds BuildpackError

module LanguagePack
  class RubyVersion
    class BadVersionError < BuildpackError
      def initialize(output = "")
        msg = ""
        msg << output
        msg << "Can not parse Ruby Version:\n"
        msg << "Valid versions listed on: https://devcenter.heroku.com/articles/ruby-support\n"
        super msg
      end
    end

    BOOTSTRAP_VERSION_NUMBER = "3.3.9".freeze
    DEFAULT_VERSION_NUMBER = "3.3.9".freeze
    DEFAULT_VERSION        = "ruby-#{DEFAULT_VERSION_NUMBER}".freeze
    RUBY_VERSION_REGEX     = %r{
        (?<ruby_version>\d+\.\d+\.\d+){0}
        (?<patchlevel>p-?\d+){0}
        (?<engine>\w+){0}
        (?<engine_version>.+){0}

        ruby-\g<ruby_version>(-\g<patchlevel>)?(\.(?<pre>\S*))?(-\g<engine>-\g<engine_version>)?
      }x

    # String formatted `<major>.<minor>.<patch>` for Ruby and JRuby
    attr_reader :ruby_version,
      # `engine` is `:ruby` or `:jruby`
      :engine,
      # `engine_version` is the Jruby version or for MRI it is the same as `ruby_version`
      # i.e. `<major>.<minor>.<patch>`
      :engine_version

    def self.bundle_platform_ruby(bundler_output:, last_version: nil)
      default = bundler_output.empty?
      if default
        default(last_version: last_version)
      elsif md = RUBY_VERSION_REGEX.match(bundler_output)
        new(
          pre: md[:pre],
          engine: md[:engine]&.to_sym || :ruby,
          default: default,
          ruby_version: md[:ruby_version],
          engine_version: md[:engine_version] || md[:ruby_version],
        )
      else
        raise BadVersionError.new("'#{bundler_output}' is not valid") unless md
      end
    end

    def self.from_gemfile_lock(ruby: , last_version: nil)
      if ruby.empty?
        default(last_version: last_version)
      else
        new(
          pre: ruby.pre,
          engine: ruby.engine,
          default: false,
          ruby_version: ruby.ruby_version,
          engine_version: ruby.engine_version,
        )
      end
    end

    def self.default(last_version: )
      ruby_version = last_version&.split("-")&.last || DEFAULT_VERSION_NUMBER
      new(
        pre: nil,
        engine: :ruby,
        default: true,
        ruby_version: ruby_version,
        engine_version: ruby_version,
      )
    end

    def initialize(
        pre:,
        engine:,
        default:,
        ruby_version:,
        engine_version:
      )
        @pre = pre
        @engine = engine
        @default = default
        @ruby_version = ruby_version
        @engine_version = engine_version
    end

    # i.e. `ruby-3.4.2`
    def version_for_download
      if @engine == :jruby
        "ruby-#{ruby_version}-jruby-#{engine_version}"
      elsif @pre
        "ruby-#{ruby_version}.#{@pre}"
      else
        "ruby-#{ruby_version}"
      end
    end

    def file_name
      "#{version_for_download}.tgz"
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

    def major
      @ruby_version.split(".")[0].to_i
    end

    def minor
      @ruby_version.split(".")[1].to_i
    end

    def patch
      @ruby_version.split(".")[2].to_i
    end

    # Returns the next logical version in the minor series
    # for example if the current ruby version is
    # `ruby-2.3.1` then then `next_logical_version(1)`
    # will produce `ruby-2.3.2`.
    def next_logical_version(increment = 1)
      "ruby-#{major}.#{minor}.#{patch + increment}"
    end

    def next_minor_version(increment = 1)
      "ruby-#{major}.#{minor + increment}.0"
    end

    def next_major_version(increment = 1)
      "ruby-#{major + increment}.0.0"
    end
  end
end
