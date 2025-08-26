require 'yaml'
require 'json'
require 'pathname'

# Observability reporting for builds
#
# Example usage:
#
#   HerokuBuildReport::GLOBAL.capture(
#     "ruby_version" => "3.4.2"
#   )
module HerokuBuildReport
  # Accumulates data in memory and writes it to the specified path in JSON format
  #
  # Writes data to disk on every capture. Later `bin/report` emits the disk contents
  class JsonReport
    MALFORMED_JSON_KEY = "build_report_file_malformed"
    attr_reader :data

    def initialize(path: , io: $stdout)
      @io = io
      @path = Pathname(path).expand_path
      @path.dirname.mkpath
      FileUtils.touch(@path)
      @data = safe_load(@path.read)

      if @data[MALFORMED_JSON_KEY]
        @path.write(@data.to_json)
      end
    end

    def safe_load(contents)
      if !contents || contents.empty?
        {}
      else
        JSON.parse(contents)
      end
    rescue => e
      @io.puts "Internal Warning: Expected build report to be JSON, but it is malformed: #{contents.inspect}"
      { MALFORMED_JSON_KEY => true }
    end

    def complex_object?(value)
      value.to_yaml.match?(/!ruby\/object:/)
    end

    def capture(metrics = {})
      metrics.each do |(key, value)|
        return if key.nil? || key.to_s.strip.empty?

        key = key&.strip
        raise "Key cannot be empty (#{key.inspect} => #{value})" if key.nil? || key.empty?

        # Don't serialize complex values by accident
        if complex_object?(value)
          value = value.to_s
        end

        @data["#{key}"] = value
      end

      @path.write(@data.to_json)
    end
  end

  # Current load order of the various "language packs"
  def self.set_global(path: )
    JsonReport.new(path: path).tap { |report|
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
    JsonReport.new(path: "/dev/null")
  end

  GLOBAL = self.dev_null # Changed via `set_global`
end
