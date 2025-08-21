require 'spec_helper'

describe "Build report" do
  it "handles complex object serialization by converting them to strings" do
    Dir.mktmpdir do |dir|
      path = Pathname(dir).join(".report.yml")
      report = HerokuBuildReport::JsonReport.new(
        path: path
      )
      value = Gem::Version.new("3.4.2")
      expect(report.complex_object?(value)).to eq(true)
      expect(value.to_yaml).to_not eq(value.to_s.to_yaml)
      report.capture("key" => value)

      expect(report.data).to eq({"key" => "3.4.2"})
      expect(path.read.strip).to eq(<<~EOF.strip)
        {"key":"3.4.2"}
      EOF
    end
  end

  it "writes valid yaml" do
    Dir.mktmpdir do |dir|
      path = Pathname(dir).join(".report.yml")
      report = HerokuBuildReport::JsonReport.new(
        path: path
      )
      report.capture(
        "string" => "'with single quotes'",
        "string_plain" => "plain",
        "number" => 22,
        "boolean" => true,
      )

      parsed = JSON.parse(path.read).sort_by {|k, _| k}.to_h
      expect(parsed).to eq(
        {
          "string" => "'with single quotes'",
          "string_plain" => "plain",
          "number" => 22,
          "boolean" => true
        }
      )
    end
  end
end
