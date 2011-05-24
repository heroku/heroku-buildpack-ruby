require "language_pack"
require "pathname"
require "yaml"

class LanguagePack::Base

  attr_reader :build_path, :cache_path

  def initialize(build_path, cache_path=nil)
    @build_path = build_path
    @cache_path = cache_path

    Dir.chdir build_path
  end

  def self.===(build_path)
    raise "must subclass"
  end

  def name
    raise "must subclass"
  end

  def default_addons
    raise "must subclass"
  end

  def default_config_vars
    raise "must subclass"
  end

  def default_process_types
    raise "must subclass"
  end

  def compile
  end

  def release
    {
      "addons" => default_addons,
      "config_vars" => default_config_vars,
      "default_process_types" => default_process_types
    }.to_yaml
  end

private ##################################

  def error(message)
    Kernel.puts " !"
    message.split("\n").each do |line|
      Kernel.puts " !     #{line.strip}"
    end
    Kernel.puts " !"
    exit 1
  end

  def run(command)
    %x{ #{command} 2>&1 }
  end

  def pipe(command)
    IO.popen(command) do |io|
      until io.eof?
        puts io.gets
      end
    end
  end

  def topic(message)
    Kernel.puts "-----> #{message}"
    $stdout.flush
  end

  def puts(message)
    message.split("\n").each do |line|
      super "       #{line.strip}"
    end
    $stdout.flush
  end

  def cache_base
    Pathname.new(cache_path)
  end

  def cache_clear(path)
    target = (cache_base + path)
    target.exist? && target.rmtree
  end

  def cache_store(path, clear_first=true)
    cache_clear(path) if clear_first
    cache_copy path, (cache_base + path)
  end

  def cache_load(path)
    cache_copy (cache_base + path), path
  end

  def cache_copy(from, to)
    return false unless File.exist?(from)
    FileUtils.mkdir_p File.dirname(to)
    system("cp -ax #{from}/. #{to}")
  end

end

