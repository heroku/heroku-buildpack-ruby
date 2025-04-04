require 'yaml'
require 'pathname'

# Observability reporting for builds
#
# Example usage:
#
#   HerokuBuildReport::GLOBAL.capture(
#     "ruby_version" => "3.4.2"
#   )
module HerokuBuildReport
  # Accumulates data in memory and writes it to the specified path in YAML format
  #
  # Writes data to disk on every capture. Later `bin/report` emits the disk contents
  class YamlReport
    attr_reader :data

    def initialize(path: )
      @path = Pathname(path).expand_path
      @path.dirname.mkpath
      FileUtils.touch(@path)
      @data = {}
    end

    def clear!
      @data.clear
      @path.write("")
    end

    def complex_object?(value)
      value.to_yaml.match?(/!ruby\/object:/)
    end

    def capture(metrics = {})
      metrics.each do |(key, value)|
        return if key.nil? || key.to_s.strip.empty?

        key = key&.strip
        raise "Key  cannot be empty (#{key.inspect} => #{value})" if key.nil? || key.empty?

        # Don't serialize complex values by accident
        if complex_object?(value)
          value = value.to_s
        end

        @data["#{key}"] = value
      end

      @path.write(@data.to_yaml)
    end
  end

  # Current load order of the various "language packs"
  def self.set_global(path: )
    YamlReport.new(path: path).tap { |report|
      # Silence warning about setting a constant
      begin
        old_verbose = $VERBOSE
        $VERBOSE = nil
        const_set(:GLOBAL, report)
      ensure
        $VERBOSE = old_verbose
      end
    }
  end

  # Stores data in memory only, does not persist to disk
  def self.dev_null
    YamlReport.new(path: "/dev/null")
  end

  GLOBAL = self.dev_null # Changed via `set_global`
end
