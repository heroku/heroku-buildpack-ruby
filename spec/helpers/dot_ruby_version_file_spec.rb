require "spec_helper"

describe "DotRubyVersionFile" do
  it "parses a plain version" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "3.4.8").call
    expect(result.ruby_version).to be_a(LanguagePack::RubyVersion)
    expect(result.ruby_version.ruby_version).to eq("3.4.8")
    expect(result.ruby_version.engine).to eq(:ruby)
    expect(result.ruby_version.engine_version).to eq("3.4.8")
    expect(result.ruby_version.default?).to eq(false)
    expect(result.warnings).to eq([])
  end

  it "strips ruby- prefix" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "ruby-3.4.8").call
    expect(result.ruby_version.ruby_version).to eq("3.4.8")
    expect(result.ruby_version.engine).to eq(:ruby)
    expect(result.warnings).to eq([])
  end

  it "trims trailing comment" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "ruby-3.4.8 # our version").call
    expect(result.ruby_version.ruby_version).to eq("3.4.8")
    expect(result.warnings).to eq([])

    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "ruby-3.4.8# our version").call
    expect(result.ruby_version.ruby_version).to eq("3.4.8")
    expect(result.warnings).to eq([])
  end

  it "strips @company-name suffix with ruby- prefix" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "ruby-3.4.8@company-name").call
    expect(result.ruby_version.ruby_version).to eq("3.4.8")
    expect(result.warnings).to eq([])

    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "ruby-3.4.8@company=>name").call
    expect(result.ruby_version.ruby_version).to eq("3.4.8")
    expect(result.warnings).to eq([])
  end

  it "strips @org suffix from plain version" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "3.4.8@myorg").call
    expect(result.ruby_version.ruby_version).to eq("3.4.8")
    expect(result.warnings).to eq([])
  end

  it "skips comments and blank lines" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: <<~EOF).call
      # This is a comment

      3.4.8
    EOF
    expect(result.ruby_version.ruby_version).to eq("3.4.8")
    expect(result.warnings).to eq([])
  end

  it "strips leading and trailing whitespace from the version line" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "  3.4.8  \n").call
    expect(result.ruby_version.ruby_version).to eq("3.4.8")
    expect(result.warnings).to eq([])
  end

  it "parses pre-release with dot syntax" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "3.4.0.rc1").call
    expect(result.ruby_version.ruby_version).to eq("3.4.0")
    expect(result.ruby_version.pre).to eq("rc1")
    expect(result.ruby_version.version_for_download).to eq("ruby-3.4.0.rc1")
    expect(result.warnings).to eq([])
  end

  it "normalizes pre-release dash syntax to dot syntax" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "3.4.0-preview2").call
    expect(result.ruby_version.ruby_version).to eq("3.4.0")
    expect(result.ruby_version.pre).to eq("preview2")
    expect(result.ruby_version.version_for_download).to eq("ruby-3.4.0.preview2")
    expect(result.warnings).to eq([])
  end

  it "normalizes pre-release with ruby- prefix" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "ruby-3.4.0-rc1").call
    expect(result.ruby_version.ruby_version).to eq("3.4.0")
    expect(result.ruby_version.pre).to eq("rc1")
    expect(result.ruby_version.version_for_download).to eq("ruby-3.4.0.rc1")
    expect(result.warnings).to eq([])
  end

  it "handles combined prefix strip, gemset strip, and pre-release" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "ruby-3.4.0-rc1@gemset").call
    expect(result.ruby_version.ruby_version).to eq("3.4.0")
    expect(result.ruby_version.pre).to eq("rc1")
    expect(result.ruby_version.version_for_download).to eq("ruby-3.4.0.rc1")
    expect(result.warnings).to eq([])
  end

  it "handles CRLF line endings" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "3.4.8\r\n").call
    expect(result.ruby_version.ruby_version).to eq("3.4.8")
    expect(result.ruby_version.version_for_download).to eq("ruby-3.4.8")
    expect(result.warnings).to eq([])
  end

  it "is empty for an empty string" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "").call
    expect(result.ruby_version).to be_nil
    expect(result.warnings).to eq([])
  end

  it "is empty for only whitespace" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "   \n  \n").call
    expect(result.ruby_version).to be_nil
    expect(result.warnings).to eq([])
  end

  it "is empty for only comments" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "# just a comment\n# another").call
    expect(result.ruby_version).to be_nil
    expect(result.warnings).to eq([])
  end

  it "warns for multiple meaningful lines" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: <<~EOF).call
      3.4.8
      3.5.0
    EOF
    expect(result.ruby_version).to be_nil
    expect(result.warnings.length).to eq(1)
    expect(result.warnings.first).to include("multiple version lines")
  end

  it "warns for jruby" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "jruby-10.0.2.0").call
    expect(result.ruby_version).to be_nil
    expect(result.warnings.length).to eq(1)
    expect(result.warnings.first).to include("JRuby")
  end

  it "warns for version specifiers with >=" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "ruby >= 3.1.6, < 3.3").call
    expect(result.ruby_version).to be_nil
    expect(result.warnings.length).to eq(1)
    expect(result.warnings.first).to include("Only exact versions are supported")
  end

  it "warns for ~> specifier" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "~> 3.1").call
    expect(result.ruby_version).to be_nil
    expect(result.warnings.length).to eq(1)
    expect(result.warnings.first).to include("Only exact versions are supported")
  end

  it "warns for >= specifier" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: ">= 3.1.6").call
    expect(result.ruby_version).to be_nil
    expect(result.warnings.length).to eq(1)
    expect(result.warnings.first).to include("Only exact versions are supported")
  end

  it "warns for garbage input" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "not-a-version").call
    expect(result.ruby_version).to be_nil
    expect(result.warnings.length).to eq(1)
    expect(result.warnings.first).to include("Cannot parse Ruby version from")
  end

  it "warns for two-part version like 3.4" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "3.4").call
    expect(result.ruby_version).to be_nil
    expect(result.warnings.length).to eq(1)
    expect(result.warnings.first).to include("Only full Ruby versions with major, minor, and patch are supported")
  end

  it "does not crash on bare ruby- prefix" do
    result = LanguagePack::Helpers::DotRubyVersionFile.new(contents: "ruby-").call
    expect(result.ruby_version).to be_nil
    expect(result.warnings.length).to eq(1)
    expect(result.warnings.first).to include("Cannot parse Ruby version from")
  end
end
