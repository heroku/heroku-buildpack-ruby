require 'spec_helper'

describe "Build report" do
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
