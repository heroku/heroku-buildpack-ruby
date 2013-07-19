require "language_pack/shell_helpers"

module LanguagePack
  class RubyVersion
    include LanguagePack::ShellHelpers

    DOT_RV_FILE     = ".ruby-version"
    DEFAULT_VERSION = "ruby-2.0.0"
    LEGACY_VERSION  = "ruby-1.9.2"

    attr_reader :set

    def initialize(bundler_path, app = {})
      @version      = ""
      @app          = app
      @bundler_path = bundler_path
      @set          = nil
    end

    def gemfile
      old_system_path = "/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin"
      run_stdout("env PATH=#{@bundler_path}/bin:#{old_system_path} GEM_PATH=#{@bundler_path} bundle platform --ruby").chomp
    end

    def env_var
      ENV['RUBY_VERSION']
    end

    def ruby_version_file
      rv = File.read(DOT_RV_FILE).chomp
      if rv.match(/^\d/)
        "ruby-#{rv}"
      else
        rv
      end
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

    def version
      return @version unless @version.empty?

      if File.exists?(DOT_RV_FILE)
        @set     = :ruby_version
        @version = ruby_version_file
      else
        bundler_output = gemfile
        if bundler_output == "No ruby version specified" && env_var
          # for backwards compatibility.
          # this will go away in the future
          @set     = :env_var
          @version = env_var
        elsif bundler_output == "No ruby version specified"
          @set     = false
          @version = none
        else
          @set     = :gemfile
          @version = bundler_output.sub('(', '').sub(')', '').split.join('-')
        end
      end
    end
  end
end
