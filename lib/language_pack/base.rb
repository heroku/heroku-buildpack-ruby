require "language_pack"
require "pathname"
require "yaml"
require "digest/sha1"
require "language_pack/shell_helpers"
require "language_pack/cache"
require "language_pack/helpers/bundler_cache"
require "language_pack/metadata"
require "language_pack/fetcher"

Encoding.default_external = Encoding::UTF_8 if defined?(Encoding)

# abstract class that all the Ruby based Language Packs inherit from
class LanguagePack::Base
  include LanguagePack::ShellHelpers
  extend LanguagePack::ShellHelpers

  VENDOR_URL           = ENV['BUILDPACK_VENDOR_URL'] || "https://heroku-buildpack-ruby.s3.us-east-1.amazonaws.com"
  ROOT_DIR             = File.expand_path("../../..", __FILE__)
  MULTI_ARCH_STACKS    = ["heroku-24"]
  KNOWN_ARCHITECTURES  = ["amd64", "arm64"]

  attr_reader :app_path, :bundler, :cache, :environment_name, :stack

  def initialize(app_path: , arch: , bundler: , cache_path: , environment_name: , gemfile_lock: , new_app: , ruby_version: , warn_io: )
    @app_path = app_path
    @arch = arch
    @bundler = bundler
    @environment_name = environment_name
    @gemfile_lock = gemfile_lock
    @new_app = new_app
    @ruby_version = ruby_version
    @warn_io = warn_io
    @stack         = ENV.fetch("STACK")
    @cache         = LanguagePack::Cache.new(cache_path)
    @metadata      = LanguagePack::Metadata.new(cache_path: cache_path)
    @bundler_cache = LanguagePack::BundlerCache.new(@cache, @stack)
    @fetchers      = {:buildpack => LanguagePack::Fetcher.new(VENDOR_URL) }
    @report = HerokuBuildReport::GLOBAL
  end

  def self.get_arch
    command = "dpkg --print-architecture"
    arch = run!(command, silent: true).strip

    if !KNOWN_ARCHITECTURES.include?(arch)
      raise <<~EOF
        Architecture '#{arch}' returned from command `#{command}` is unknown.
        Known architectures include: #{KNOWN_ARCHITECTURES.inspect}"
      EOF
    end

    arch
  end

  def new_app?
    @new_app
  end

  def self.===(app_path)
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

  # process types to provide for the app
  # Ex. for rails we provide a web process
  # @return [Hash] the result
  def default_process_types
    raise "must subclass"
  end

  # this is called to build the slug
  def compile
    write_release_yaml
    Kernel.puts ""
    warnings.each do |warning|
      Kernel.puts "\e[1m\e[33m###### WARNING:\e[0m"# Bold yellow
      Kernel.puts ""
      puts warning
      Kernel.puts ""
    end
    Kernel.puts ""
  end

  def build_release
    release = {}
    release["addons"]                = default_addons
    release["default_process_types"] = default_process_types

    release
  end

  def write_release_yaml
    release = build_release
    FileUtils.mkdir("tmp") unless File.exist?("tmp")
    File.open("tmp/heroku-buildpack-release-step.yml", 'w') do |f|
      f.write(release.to_yaml)
    end

    warn_webserver
  end

  def warn_webserver
    return if File.exist?("Procfile")
    msg =  "No Procfile detected, using the default web server.\n"
    msg << "We recommend explicitly declaring how to boot your server process via a Procfile.\n"
    msg << "https://devcenter.heroku.com/articles/ruby-default-web-server"
    warn msg
  end

private ##################################


  def add_to_profiled(string, filename: "ruby.sh", mode: "a")
    profiled_path = "#{app_path}/.profile.d/"

    FileUtils.mkdir_p profiled_path
    File.open("#{profiled_path}/#{filename}", mode) do |file|
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
  def export(key, val, option: nil)
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

  def set_export_default(key, val)
    export key, val, option: :default
  end

  def set_export_override(key, val)
    export key, val, option: :override
  end

  def set_export_path(key, val)
    export key, val, option: :path
  end
end
