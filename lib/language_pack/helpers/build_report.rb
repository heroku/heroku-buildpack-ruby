require 'yaml'
require 'pathname'

# Accumulates metrics
#
# Stores values in memory until explicitly written to disk
class LanguagePack::Helpers::BuildReport
  attr_reader :data

  # Current load order of the various "language packs"
  def self.set_global(cache_path: )
    cache_path = Pathname(cache_path)
    # Coupled with `bin/report`
    path = cache_path.join("vendor").join(".heroku_build_report.yml")
    repot = new(path: path)
    const_set(:GLOBAL, report)
    report
  end

  # Stores data in memory only, does not persist to disk
  def self.dev_null
    new(path: "/dev/null")
  end

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

class LanguagePack::Helpers::BuildReport
  GLOBAL = self.dev_null # Changed via `set_global`
end
