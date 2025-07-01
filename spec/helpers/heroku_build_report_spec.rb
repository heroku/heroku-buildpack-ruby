require 'spec_helper'

describe "Build report" do
  it "handles complex object serialization by converting them to strings" do
    Dir.mktmpdir do |dir|
      path = Pathname(dir).join(".report.yml")
      report = HerokuBuildReport::YamlReport.new(
        path: path
      )
      value = Gem::Version.new("3.4.2")
      expect(report.complex_object?(value)).to eq(true)
      expect(value.to_yaml).to_not eq(value.to_s.to_yaml)
      report.capture("key" => value)

      expect(report.data).to eq({"key" => "3.4.2"})
      expect(path.read).to eq(<<~EOF)
        ---
        key: 3.4.2
      EOF
    end
  end

  it "writes valid yaml" do
    Dir.mktmpdir do |dir|
      path = Pathname(dir).join(".report.yml")
      report = HerokuBuildReport::YamlReport.new(
        path: path
      )
      report.capture(
        "string" => "'with single quotes'",
        "string_plain" => "plain",
        "number" => 22,
        "boolean" => true,
      )

      expect(path.read).to eq(<<~EOF)
        ---
        string: "'with single quotes'"
        string_plain: plain
        number: 22
        boolean: true
      EOF
    end
  end
end
