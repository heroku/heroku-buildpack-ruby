require 'fileutils'
require 'toml'

class LanguagePack::Helpers::Layer
  attr_reader :path

  def initialize(layer_dir, name, launch: false, build: false, cache: false)
    @layer_dir = layer_dir
    @name = name
    @path = Pathname.new "#{@layer_dir}/#{@name}"
    @toml = if File.exist?(toml_file)
              TOML.load(File.read(toml_file))
            else
              Hash.new
            end

    @toml[:launch] = launch
    @toml[:build] = build
    @toml[:cache] = cache
    if File.exist?(toml_file)
      @toml[:metadata] = TOML.load(File.read(toml_file))[:metadata]
    end
    @toml[:metadata] ||= Hash.new

    FileUtils.mkdir_p(@path)
    write
  end

  def metadata
    @toml[:metadata]
  end

  def toml_file
    @toml_file ||= "#{@layer_dir}/#{@name}.toml"
  end

  def write
    File.open(toml_file, "w") do |file|
      file.write TOML::Dumper.new(@toml).to_s
    end
  end

  def validate!
    valid, messages = yield metadata
    unless valid
      if messages.class.included_modules.include?(Enumerable)
        messages.each {|message| puts message }
      else
        puts messages
      end
      @path.rmtree
    end
  end
end
