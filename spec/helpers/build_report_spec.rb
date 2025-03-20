require 'spec_helper'

describe "Build report" do
  it "writes valid yaml" do
    Dir.mktmpdir do |dir|
      path = Pathname(dir).join(".report.yml")
      report = LanguagePack::Helpers::BuildReport.new(
        path: path
      )
      report.capture(key: "string", value: "'with single quotes'")
      report.capture(key: "string_plain", value: "plain")
      report.capture(key: "number", value: 22)
      report.capture(key: "boolean", value: true)
      report.store

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
