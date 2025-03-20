require 'yaml'

class LanguagePack::Helpers::BuildReport
  def initialize(path: )
    @path = Pathname(path).expand_path
    @path.dirname.mkpath
    FileUtils.touch(@path)
    @report = {}
  end

  def capture(key: , value: )
    return if key.nil? || key.to_s.strip.empty?

    key = key&.strip
    raise "Key cannot be empty" if key.nil? || key.empty?

    @report["ruby_#{key}"] = value
  end

  def store
    return if @report.empty?
    @path.write(@report.to_yaml)
  end
end
