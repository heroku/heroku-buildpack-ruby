require "language_pack/shell_helpers"

module LanguagePack
  class RubyVersion
    include LanguagePack::ShellHelpers

    DEFAULT_VERSION = "ruby-2.0.0"
    LEGACY_VERSION  = "ruby-1.9.2"

    attr_reader :set, :version, :version_without_patchlevel, :patchlevel, :engine, :ruby_version, :engine_version

    def initialize(bundler_path, app = {})
      @set          = nil
      @bundler_path = bundler_path
      @app          = app
      set_version
      parse_version

      @version_without_patchlevel = @version.sub(/-p[\d]+/, '')
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

    private
    def gemfile
      old_system_path = "/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin"
      run_stdout("env PATH=#{@bundler_path}/bin:#{old_system_path} GEM_PATH=#{@bundler_path} bundle platform --ruby").chomp
    end

    def none
      if @app[:new]
        DEFAULT_VERSION
      elsif @app[:last_version]
        @app[:last_version]
      else
        LEGACY_VERSION
      end
    end

    def set_version
      bundler_output = gemfile
      if bundler_output == "No ruby version specified"
        @set     = false
        @version = none
      else
        @set     = :gemfile
        @version = bundler_output.sub('(', '').sub(')', '').split.join('-')
      end
    end

    def parse_version
      regex = %r{
        (?<ruby_version>\d+\.\d+\.\d+){0}
        (?<patchlevel>p\d+){0}
        (?<engine>\w+){0}
        (?<engine_version>.+){0}

        ruby-\g<ruby_version>(-\g<patchlevel>)?(-\g<engine>-\g<engine_version>)?
      }x

      md = regex.match(version)
      if md
        @ruby_version   = md[:ruby_version]
        @patchlevel     = md[:patchlevel]
        @engine         = md[:engine]
        @engine_version = md[:engine_version]

        if @engine.nil?
          @engine         = :ruby
          @engine_version = @ruby_version
        end
      else
        raise "Can not parse Ruby Version: #{version}"
      end
    end
  end
end
