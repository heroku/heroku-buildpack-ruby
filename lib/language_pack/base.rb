require "language_pack"
require "pathname"
require "yaml"
require "digest/sha1"

Encoding.default_external = Encoding::UTF_8 if defined?(Encoding)

# abstract class that all the Ruby based Language Packs inherit from
class LanguagePack::Base
  VENDOR_URL = "https://s3.amazonaws.com/heroku-buildpack-ruby"

  attr_reader :build_path, :cache_path

  # changes directory to the build_path
  # @param [String] the path of the build dir
  # @param [String] the path of the cache dir
  def initialize(build_path, cache_path=nil)
    @build_path = build_path
    @cache_path = cache_path
    @id = Digest::SHA1.hexdigest("#{Time.now.to_f}-#{rand(1000000)}")[0..10]

    Dir.chdir build_path
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
  end

  # collection of values passed for a release
  # @return [String] in YAML format of the result
  def release
    setup_language_pack_environment

    {
      "addons" => default_addons,
      "config_vars" => default_config_vars,
      "default_process_types" => default_process_types
    }.to_yaml
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

  # display error message and stop the build process
  # @param [String] error message
  def error(message)
    Kernel.puts " !"
    message.split("\n").each do |line|
      Kernel.puts " !     #{line.strip}"
    end
    Kernel.puts " !"
    log "exit", :error => message
    exit 1
  end

  # run a shell comannd and pipe stderr to stdout
  # @param [String] command to be run
  # @return [String] output of stdout and stderr
  def run(command)
    %x{ #{command} 2>&1 }
  end

  # run a shell command and pipe stderr to /dev/null
  # @param [String] command to be run
  # @return [String] output of stdout
  def run_stdout(command)
    %x{ #{command} 2>/dev/null }
  end

  # run a shell command and stream the output
  # @param [String] command to be run
  def pipe(command)
    output = ""
    IO.popen(command) do |io|
      until io.eof?
        buffer = io.gets
        output << buffer
        puts buffer
      end
    end

    output
  end

  # display a topic message
  # (denoted by ----->)
  # @param [String] topic message to be displayed
  def topic(message)
    Kernel.puts "-----> #{message}"
    $stdout.flush
  end

  # display a message in line
  # (indented by 6 spaces)
  # @param [String] message to be displayed
  def puts(message)
    message.split("\n").each do |line|
      super "       #{line.strip}"
    end
    $stdout.flush
  end

  # create a Pathname of the cache dir
  # @return [Pathname] the cache dir
  def cache_base
    Pathname.new(cache_path)
  end

  # removes the the specified
  # @param [String] relative path from the cache_base
  def cache_clear(path)
    target = (cache_base + path)
    target.exist? && target.rmtree
  end

  # write cache contents
  # @param [String] path of contents to store. it will be stored using this a relative path from the cache_base.
  # @param [Boolean] defaults to true. if set to true, the cache store directory will be cleared before writing to it.
  def cache_store(path, clear_first=true)
    cache_clear(path) if clear_first
    cache_copy path, (cache_base + path)
  end

  # load cache contents
  # @param [String] relative path of the cache contents
  def cache_load(path)
    cache_copy (cache_base + path), path
  end

  # copy cache contents
  # @param [String] source directory
  # @param [String] destination directory
  def cache_copy(from, to)
    return false unless File.exist?(from)
    FileUtils.mkdir_p File.dirname(to)
    system("cp -a #{from}/. #{to}")
  end

  # check if the cache content exists
  # @param [String] relative path of the cache contents
  # @param [Boolean] true if the path exists in the cache and false if otherwise
  def cache_exists?(path)
    File.exists?(cache_base + path)
  end
end

