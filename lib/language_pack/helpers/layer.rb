require 'fileutils'
require 'toml'

class LanguagePack::Helpers::Layer
  attr_reader :path

  # Launch: True if you want the layer to exist in the final image, for example
  # if you want maven for building an app but don't want it to boot the image.
  # Build: True if you want to make the results of this buildpack available to other
  # buildpacks in the compilation process.
  # Cache: True if you want the layer to be pulled back in on the next build. False
  # means the layer dir for this component will be empty on the next time.
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

  # Key value store per layer
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
