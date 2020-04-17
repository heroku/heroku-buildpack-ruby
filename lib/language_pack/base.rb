require "language_pack"
require "pathname"
require "yaml"
require "digest/sha1"
require "language_pack/shell_helpers"
require "language_pack/cache"
require "language_pack/helpers/bundler_cache"
require "language_pack/helpers/layer"
require "language_pack/metadata"
require "language_pack/fetcher"
require "language_pack/instrument"

Encoding.default_external = Encoding::UTF_8 if defined?(Encoding)
ENV["BPLOG_PREFIX"] = "buildpack.ruby"

# abstract class that all the Ruby based Language Packs inherit from
class LanguagePack::Base
  include LanguagePack::ShellHelpers
  extend LanguagePack::ShellHelpers

  VENDOR_URL           = ENV['BUILDPACK_VENDOR_URL'] || "https://s3-external-1.amazonaws.com/heroku-buildpack-ruby"
  DEFAULT_LEGACY_STACK = "cedar"
  ROOT_DIR             = File.expand_path("../../..", __FILE__)

  attr_reader :build_path, :cache, :stack

  # changes directory to the build_path
  # @param [String] the path of the build dir
  # @param [String] the path of the cache dir this is nil during detect and release
  def initialize(build_path, cache_path = nil, layer_dir=nil)
     self.class.instrument "base.initialize" do
      @build_path    = build_path
      @stack         = ENV.fetch("STACK")
      @cache         = LanguagePack::Cache.new(cache_path)
      @metadata      = LanguagePack::Metadata.new(@cache)
      @bundler_cache = LanguagePack::BundlerCache.new(@cache, @stack)
      @id            = Digest::SHA1.hexdigest("#{Time.now.to_f}-#{rand(1000000)}")[0..10]
      @fetchers      = {:buildpack => LanguagePack::Fetcher.new(VENDOR_URL) }
      @layer_dir     = layer_dir

      Dir.chdir build_path
    end
  end

  def instrument(*args, &block)
    self.class.instrument(*args, &block)
  end

  def self.instrument(*args, &block)
    LanguagePack::Instrument.instrument(*args, &block)
  end

  def self.===(build_path)
    raise "must subclass"
  end

  # name of the Language Pack
  # @return [String] the result
  def name
    raise "must subclass"
  end

  # list of default addons to install
  def default_addons
    raise "must subclass"
  end

  # config vars to be set on first push.
  # @return [Hash] the result
  # @not: this is only set the first time an app is pushed to.
  def default_config_vars
    raise "must subclass"
  end

  # process types to provide for the app
  # Ex. for rails we provide a web process
  # @return [Hash] the result
  def default_process_types
    raise "must subclass"
  end

  # this is called to build the slug
  def compile
    write_release_yaml
    instrument 'base.compile' do
      Kernel.puts ""
      warnings.each do |warning|
        Kernel.puts "\e[1m\e[33m###### WARNING:\e[0m"# Bold yellow
        Kernel.puts ""
        puts warning
        Kernel.puts ""
      end
      if deprecations.any?
        topic "DEPRECATIONS:"
        puts @deprecations.join("\n")
      end
      Kernel.puts ""
    end
    mcount "success"
  end

  def build
    write_release_toml
    instrument 'base.compile' do
      Kernel.puts ""
      warnings.each do |warning|
        Kernel.puts "\e[1m\e[33m###### WARNING:\e[0m"# Bold yellow
        Kernel.puts ""
        puts warning
        Kernel.puts ""
        Kernel.puts ""
      end
      if deprecations.any?
        topic "DEPRECATIONS:"
        puts @deprecations.join("\n")
      end
      Kernel.puts ""
    end
    mcount "success"
  end

  def build_release
    release = {}
    release["addons"]                = default_addons
    release["config_vars"]           = default_config_vars
    release["default_process_types"] = default_process_types

    release
  end

  def write_release_toml
    release = build_release

    layer = LanguagePack::Helpers::Layer.new(@layer_dir, "env", launch: true)
    FileUtils.mkdir_p("#{layer.path}/env.launch")
    release["config_vars"].each do |key, value|
      File.open("#{layer.path}/env.launch/#{key.upcase}.override", 'w') do |f|
        f.write(value)
      end
    end

    release_toml = release["default_process_types"].map do |type, command|
      <<PROCESSES
[[processes]]
type = "#{type}"
command = "#{command}"
PROCESSES
    end
    File.open("#{@layer_dir}/launch.toml", 'a') do |f|
      f.write(release_toml.join("\n"))
    end
  end

  def write_release_yaml
    release = build_release
    FileUtils.mkdir("tmp") unless File.exists?("tmp")
    File.open("tmp/heroku-buildpack-release-step.yml", 'w') do |f|
      f.write(release.to_yaml)
    end

    warn_webserver
  end

  # write out the release. Pick v2a or v3 release format
  def write_release
    @layer_dir ? write_release_toml : write_release_yaml
  end

  def warn_webserver
    return if File.exist?("Procfile")
    msg =  "No Procfile detected, using the default web server.\n"
    msg << "We recommend explicitly declaring how to boot your server process via a Procfile.\n"
    msg << "https://devcenter.heroku.com/articles/ruby-default-web-server"
    warn msg
  end



  # log output
  # Ex. log "some_message", "here", :someattr="value"
  def log(*args)
    args.concat [:id => @id]
    args.concat [:framework => self.class.to_s.split("::").last.downcase]

    start = Time.now.to_f
    log_internal args, :start => start

    if block_given?
      begin
        ret = yield
        finish = Time.now.to_f
        log_internal args, :status => "complete", :finish => finish, :elapsed => (finish - start)
        return ret
      rescue StandardError => ex
        finish  = Time.now.to_f
        message = Shellwords.escape(ex.message)
        log_internal args, :status => "error", :finish => finish, :elapsed => (finish - start), :message => message
        raise ex
      end
    end
  end

private ##################################

  # sets up the environment variables for the build process
  def setup_language_pack_environment
  end

  def add_to_profiled(string)
    profiled_path = @layer_dir ? "#{@layer_dir}/ruby/profile.d/" : "#{build_path}/.profile.d/"

    FileUtils.mkdir_p profiled_path
    File.open("#{profiled_path}/ruby.sh", "a") do |file|
      file.puts string
    end
  end

  def set_env_default(key, val)
    add_to_profiled "export #{key}=${#{key}:-#{val}}"
  end

  def set_env_override(key, val)
    add_to_profiled %{export #{key}="#{val.gsub('"','\"')}"}
  end

  def add_to_export(string)
    export = File.join(ROOT_DIR, "export")
    File.open(export, "a") do |file|
      file.puts string
    end
  end

  # option can be :path, :default, :override
  # https://github.com/buildpacks/spec/blob/366ac1aa0be59d11010cc21aa06c16d81d8d43e7/buildpack.md#environment-variable-modification-rules
  def export(key, val, layer: nil, option: nil)
    if layer
      # don't replace if the key is already set
      return if ENV[key] && option == :default

      filename =
        if option.nil? || option == :path
          key
        elsif option == :default
          "#{key}.override"
        else
          "#{key}.#{option}"
        end

      FileUtils.mkdir_p("#{layer.path}/env.build")
      File.open("#{layer.path}/env.build/#{filename}", "w") do |f|
        f.write(val)
      end
    else
      string =
        if option == :default
          %{export #{key}="${#{key}:-#{val}}"}
        elsif option == :path
          %{export #{key}="#{val}:$#{key}"}
        else
          %{export #{key}="#{val.gsub('"','\"')}"}
        end

      export = File.join(ROOT_DIR, "export")
      File.open(export, "a") do |file|
        file.puts string
      end
    end
  end

  def set_export_default(key, val, layer = nil)
    export key, val, layer: layer, option: :default
  end

  def set_export_override(key, val, layer = nil)
    export key, val, layer: layer, option: :override
  end

  def set_export_path(key, val, layer = nil)
    export key, val, layer: layer, option: :path
  end

  def log_internal(*args)
    message = build_log_message(args)
    %x{ logger -p user.notice -t "slugc[$$]" "buildpack-ruby #{message}" }
  end

  def build_log_message(args)
    args.map do |arg|
      case arg
        when Float then "%0.2f" % arg
        when Array then build_log_message(arg)
        when Hash  then arg.map { |k,v| "#{k}=#{build_log_message([v])}" }.join(" ")
        else arg
      end
    end.join(" ")
  end
end
