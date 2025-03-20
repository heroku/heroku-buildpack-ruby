require 'yaml'
require 'pathname'

class LanguagePack::Helpers::BuildReport
  PATH = nil # path to a report file
  attr_reader :data

  # Sets the PATH constant, returns the path to the report file
  #
  def self.set_path_from_cache(cache_path: )
    cache = Pathname(cache)
    # Coupled with `bin/report`
    report = cache.join("vendor").join(".heroku_build_report.yml")
    const_set(:PATH, report)
    report
  end

  # Main entrypoint `BuildReport.default`
  #
  # Defaults to `BuildReport::PATH` falls back to `/dev/null` if path is not specified
  def self.default(path: PATH)
    if path
      new(path: path)
    else
      dev_null
    end
  end

  def self.dev_null
    new(path: "/dev/null")
  end

  def initialize(path: )
    @path = Pathname(path).expand_path
    @path.dirname.mkpath
    FileUtils.touch(@path)
    @data = {}
  end

  def capture(key: , value: )
    return if key.nil? || key.to_s.strip.empty?

    key = key&.strip
    raise "Key cannot be empty" if key.nil? || key.empty?

    @data["#{key}"] = value
  end

  def store
    return if @data.empty?
    @path.write(@data.to_yaml)
  end
end
