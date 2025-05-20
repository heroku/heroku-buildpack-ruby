require "language_pack/shell_helpers"

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

    BOOTSTRAP_VERSION_NUMBER = "3.3.8".freeze
    DEFAULT_VERSION_NUMBER = "3.3.8".freeze
    DEFAULT_VERSION        = "ruby-#{DEFAULT_VERSION_NUMBER}".freeze
    RUBY_VERSION_REGEX     = %r{
        (?<ruby_version>\d+\.\d+\.\d+){0}
        (?<patchlevel>p-?\d+){0}
        (?<engine>\w+){0}
        (?<engine_version>.+){0}

        ruby-\g<ruby_version>(-\g<patchlevel>)?(-\g<engine>-\g<engine_version>)?
      }x


    # `version` is the bundler output like `ruby-3.4.2`
    attr_reader :version,
      # `set` is either `:gemfile` when the app specified a version or `nil` when using
      # the default version
      :set,
      # `version_without_patchlevel` removes any `-p<number>` as they're not significant
      # effectively this is `version_for_download`
      :version_without_patchlevel,
      # `patchlevel` is the `-p<number>` or is empty
      :patchlevel,
      # `engine` is `:ruby` or `:jruby`
      :engine,
      # `ruby_version` is `<major>.<minor>.<patch>` extracted from `version`
      :ruby_version,
      # `engine_version` is the Jruby version or for MRI it is the same as `ruby_version`
      # i.e. `<major>.<minor>.<patch>`
      :engine_version

    include LanguagePack::ShellHelpers

    def initialize(bundler_output:, last_version: nil)
      if bundler_output.empty?
        @set     = false
        @version = last_version || DEFAULT_VERSION
      else
        @set     = :gemfile
        @version = bundler_output
      end

      md = RUBY_VERSION_REGEX.match(version)
      raise BadVersionError.new("'#{version}' is not valid") unless md
      @ruby_version   = md[:ruby_version]
      @patchlevel     = md[:patchlevel]
      @engine_version = md[:engine_version] || @ruby_version
      @engine         = (md[:engine]        || :ruby).to_sym

      @version_without_patchlevel = @version.sub(/-p-?\d+/, '')
    end

    # https://github.com/bundler/bundler/issues/4621
    def version_for_download
      version_without_patchlevel
    end

    def file_name
      "#{version_for_download}.tgz"
    end

    def default?
      !set
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
  end
end
