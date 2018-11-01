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

    DEFAULT_VERSION_NUMBER = "2.4.5"
    DEFAULT_VERSION        = "ruby-#{DEFAULT_VERSION_NUMBER}"
    LEGACY_VERSION_NUMBER  = "1.9.2"
    LEGACY_VERSION         = "ruby-#{LEGACY_VERSION_NUMBER}"
    RUBY_VERSION_REGEX     = %r{
        (?<ruby_version>\d+\.\d+\.\d+){0}
        (?<patchlevel>p-?\d+){0}
        (?<engine>\w+){0}
        (?<engine_version>.+){0}

        ruby-\g<ruby_version>(-\g<patchlevel>)?(-\g<engine>-\g<engine_version>)?
      }x

    attr_reader :set, :version, :version_without_patchlevel, :patchlevel, :engine, :ruby_version, :engine_version
    include LanguagePack::ShellHelpers

    def initialize(bundler_output, app = {})
      @set            = nil
      @bundler_output = bundler_output
      @app            = app
      set_version
      parse_version

      @version_without_patchlevel = @version.sub(/-p-?\d+/, '')
    end

    # https://github.com/bundler/bundler/issues/4621
    def version_for_download
      if rbx?
        "rubinius-#{engine_version}"
      elsif patchlevel_is_significant? && @patchlevel && @patchlevel.sub(/p/, '').to_i >= 0
        @version
      else
        version_without_patchlevel
      end
    end

    # Before Ruby 2.1 patch releases were done via patchlevel i.e. 1.9.3-p426 versus 1.9.3-p448
    # With 2.1 and above patches are released in the "minor" version instead i.e. 2.1.0 versus 2.1.1
    def patchlevel_is_significant?
      !jruby? && Gem::Version.new(self.ruby_version) <= Gem::Version.new("2.1")
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

    # determine if we're using rbx
    # @return [Boolean] true if we are and false if we aren't
    def rbx?
      engine == :rbx
    end

    # determines if a build ruby is required
    # @return [Boolean] true if a build ruby is required
    def build?
      engine == :ruby && %w(1.8.7 1.9.2).include?(ruby_version)
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

    def set_version
      if @bundler_output.empty?
        @set     = false
        @version = none
      else
        @set     = :gemfile
        @version = @bundler_output
      end
    end

    def parse_version
      md = RUBY_VERSION_REGEX.match(version)
      raise BadVersionError.new("'#{version}' is not valid") unless md
      @ruby_version   = md[:ruby_version]
      @patchlevel     = md[:patchlevel]
      @engine_version = md[:engine_version] || @ruby_version
      @engine         = (md[:engine]        || :ruby).to_sym
    end
  end
end
