require 'fileutils'
require 'toml'

class LanguagePack::Helpers::Layer
  attr_reader :path

  def initialize(layer_dir, name, launch: false, build: false, cache: false)
    @layer_dir = layer_dir
    @name = name
    @path = "#{@layer_dir}/#{@name}"
    @toml = if File.exist?(toml_file)
              TOML.load(File.read(toml_file))
            else
              Hash.new
            end

    @toml[:launch] = launch.to_s
    @toml[:build] = build.to_s
    @toml[:cache] = cache.to_s
    @toml[:metadata] = Hash.new

    puts "Creating Layer: #{@path}"
    FileUtils.mkdir_p(@path)
    puts "Writing: #{toml_file}"
    File.open(toml_file, "w") do |file|
      file.write <<TOML
launch = #{launch}
build = #{build}
cache = #{cache}
TOML
    end
  end

  def metadata
    @toml[:metadata]
  end

  def toml_file
    @toml_file ||= "#{@layer_dir}/#{@name}.toml"
  end

  def write
    metadata_string = metadata.inject([]) do |acc, (key, value)|
      acc << "#{key} = '#{value}'"
    end

    unless metadata_string.empty?
      File.open(toml_file, "w") do |file|
        file.write <<TOML
launch = #{@toml[:launch]}
build = #{@toml[:build]}
cache = #{@toml[:cache]}

[metadata]
#{metadata_string.join("\n")}
TOML
      end
    end
  end
end
