require "language_pack/shell_helpers" # Holds BuildpackError

module LanguagePack
  class RubyVersion
    class BadVersionError < BuildpackError
      def initialize(output = "")
        msg = ""
        msg << output
        msg << "Can not parse Ruby Version:\n"
        msg << "Valid versions listed on: https://devcenter.heroku.com/articles/ruby-support\n"
        super(msg)
      end
    end

    BOOTSTRAP_VERSION_NUMBER = "3.3.9".freeze
    DEFAULT_VERSION_NUMBER = "3.3.9".freeze
    DEFAULT_VERSION = "ruby-#{DEFAULT_VERSION_NUMBER}".freeze

    # String formatted `<major>.<minor>.<patch>` for Ruby and JRuby
    attr_reader :ruby_version,
      # `engine` is `:ruby` or `:jruby`
      :engine,
      # `engine_version` is the Jruby version or for MRI it is the same as `ruby_version`
      # i.e. `<major>.<minor>.<patch>`
      :engine_version

    def self.from_gemfile_lock(ruby:, last_version: nil)
      if ruby.empty?
        default(last_version: last_version)
      else
        new(
          pre: ruby.pre,
          engine: ruby.engine,
          default: false,
          ruby_version: ruby.ruby_version,
          engine_version: ruby.engine_version
        )
      end
    end

    def self.default(last_version:)
      ruby_version = last_version&.split("-")&.last || DEFAULT_VERSION_NUMBER
      new(
        pre: nil,
        engine: :ruby,
        default: true,
        ruby_version: ruby_version,
        engine_version: ruby_version
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

    # Also used as for metrics to track unique installs
    # i.e. `ruby-3.4.2`
    def version_for_download
      if @engine == :jruby
        "ruby-#{ruby_version}-jruby-#{engine_version}"
      else
        "ruby-#{engine_version_full}"
      end
    end

    # Full qualifier for the version including pre-release information
    # i.e. `3.5.0.preview1` or `3.5.0` or `3.5.0.rc1` for ruby
    # i.e. `9.4.9.0` for jruby
    def engine_version_full
      if @engine == :jruby
        engine_version
      elsif @pre
        "#{engine_version}.#{@pre}"
      else
        engine_version.to_s
      end
    end

    # Ruby versioned bundler directory
    #
    # When installing gems via `BUNDLE_DEPLOYMENT=1 bundle install`, they're installed into a versioned directory based on the ruby version.
    #
    # This becomes the location of GEM_PATH on disk https://www.schneems.com/2014/04/15/gem-path.html.
    # - Executables are at bundler_directory.join("bin")
    # - Gems are at bundler_directory.join("gems")
    #
    # For example:
    #
    # - Ruby 3.4.7 would be "vendor/bundle/ruby/3.4.0"
    # - JRuby 9.4.14.0 would be "vendor/bundle/jruby/3.1.0" (As it implements Ruby 3.1.7 spec)
    def bundler_directory
      "vendor/bundle/#{engine}/#{major}.#{minor}.0"
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
