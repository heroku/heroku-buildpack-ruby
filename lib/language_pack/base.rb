require "language_pack"
require "pathname"
require "yaml"
require "digest/sha1"
require "language_pack/shell_helpers"
require "language_pack/cache"
require "language_pack/metadata"
require "language_pack/fetcher"
require "language_pack/instrument"

Encoding.default_external = Encoding::UTF_8 if defined?(Encoding)

# abstract class that all the Ruby based Language Packs inherit from
class LanguagePack::Base
  include LanguagePack::ShellHelpers

  VENDOR_URL = "https://s3-external-1.amazonaws.com/heroku-buildpack-ruby"

  attr_reader :build_path, :cache

  # changes directory to the build_path
  # @param [String] the path of the build dir
  # @param [String] the path of the cache dir this is nil during detect and release
  def initialize(build_path, cache_path=nil)
     self.class.instrument "base.initialize" do
      @build_path   = build_path
      @cache        = LanguagePack::Cache.new(cache_path) if cache_path
      @metadata     = LanguagePack::Metadata.new(@cache)
      @id           = Digest::SHA1.hexdigest("#{Time.now.to_f}-#{rand(1000000)}")[0..10]
      @warnings     = []
      @deprecations = []
      @fetchers     = {:buildpack => LanguagePack::Fetcher.new(VENDOR_URL) }

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
    instrument 'base.compile' do
      if @warnings.any?
        topic "WARNINGS:"
        puts @warnings.join("\n")
      end
      if @deprecations.any?
        topic "DEPRECATIONS:"
        puts @deprecations.join("\n")
      end
    end
  end

  # collection of values passed for a release
  # @return [String] in YAML format of the result
  def release
    instrument "base.release" do
      setup_language_pack_environment

      {
        "addons" => default_addons,
        "default_process_types" => default_process_types
      }.to_yaml
    end
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
        finish = Time.now.to_f
        log_internal args, :status => "error", :finish => finish, :elapsed => (finish - start), :message => ex.message
        raise ex
      end
    end
  end

private ##################################

  # sets up the environment variables for the build process
  def setup_language_pack_environment
  end

  def add_to_profiled(string)
    FileUtils.mkdir_p "#{build_path}/.profile.d"
    File.open("#{build_path}/.profile.d/ruby.sh", "a") do |file|
      file.puts string
    end
  end

  def set_env_default(key, val)
    add_to_profiled "export #{key}=${#{key}:-#{val}}"
  end

  def set_env_override(key, val)
    add_to_profiled %{export #{key}="#{val.gsub('"','\"')}"}
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

