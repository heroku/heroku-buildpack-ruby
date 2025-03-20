require 'yaml'

class LanguagePack::Helpers::BuildReport
  attr_reader :data

  def initialize(path: )
    @path = Pathname(path).expand_path
    @path.dirname.mkpath
    FileUtils.touch(@path)
    @data = {}
  end

  def self.dev_null
    new(path: "/dev/null")
  end

  def capture(key: , value: )
    return if key.nil? || key.to_s.strip.empty?

    key = key&.strip
    raise "Key cannot be empty" if key.nil? || key.empty?

    @data["ruby_#{key}"] = value
  end

  def store
    return if @report.empty?
    @data.write(@report.to_yaml)
  end
end
