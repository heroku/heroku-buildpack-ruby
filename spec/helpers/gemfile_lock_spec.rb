require "spec_helper"

describe LanguagePack::Helpers::GemfileLock do
  it "parses empty gemfile without error" do
    report = HerokuBuildReport.dev_null
    gemfile_lock = LanguagePack::Helpers::GemfileLock.new(
      report: report,
      contents: ""
    )
    expect(gemfile_lock.ruby.ruby_version).to eq(nil)
    expect(gemfile_lock.ruby.pre).to eq(nil)
    expect(gemfile_lock.ruby.engine).to eq(:ruby)
    expect(gemfile_lock.ruby.empty?).to eq(true)
    expect(gemfile_lock.ruby.engine_version).to eq(nil)

    expect(gemfile_lock.bundler.version).to eq(nil)
    expect(gemfile_lock.bundler.empty?).to eq(true)
    expect(report.data).to be_empty
  end

  it "records invalid parsing" do
    report = HerokuBuildReport.dev_null
    gemfile_lock = LanguagePack::Helpers::GemfileLock.new(
      report: report,
      contents: <<~EOF
        RUBY VERSION
        ruby 3.3.5p100
        BUNDLED WITH
        2.3.4
      EOF
    )
    expect(
      report.data["gemfile_lock.bundler_version.failed_parse"]
    ).to eq(true)
    expect(
      report.data["gemfile_lock.bundler_version.failed_contents"]
    ).to eq(<<~EOF.strip)
      BUNDLED WITH
      2.3.4
    EOF

    expect(
      report.data["gemfile_lock.ruby_version.failed_parse"]
    ).to eq(true)
    expect(
      report.data["gemfile_lock.ruby_version.failed_contents"]
    ).to eq(<<~EOF.strip)
      RUBY VERSION
      ruby 3.3.5p100
    EOF
  end

  it "captures MRI version and ignores patchlevel" do
    gemfile_lock = LanguagePack::Helpers::GemfileLock.new(
      contents: <<~EOF
        RUBY VERSION
           ruby 3.3.5p100
        BUNDLED WITH
           2.3.4
      EOF
    )
    expect(gemfile_lock.ruby.ruby_version).to eq("3.3.5")
    expect(gemfile_lock.ruby.pre).to eq(nil)
    expect(gemfile_lock.ruby.engine).to eq(:ruby)
    expect(gemfile_lock.ruby.empty?).to eq(false)
    expect(gemfile_lock.ruby.engine_version).to eq("3.3.5")

    expect(gemfile_lock.bundler.version).to eq("2.3.4")
    expect(gemfile_lock.bundler.empty?).to eq(false)
  end

  it "works with windows line endings" do
    gemfile_lock = LanguagePack::Helpers::GemfileLock.new(
      contents: <<~EOF.gsub("\n", "\r\n")
        RUBY VERSION
           ruby 3.3.5p100
        BUNDLED WITH
           2.3.4
      EOF
    )
    expect(gemfile_lock.ruby.ruby_version).to eq("3.3.5")
    expect(gemfile_lock.ruby.pre).to eq(nil)
    expect(gemfile_lock.ruby.engine).to eq(:ruby)
    expect(gemfile_lock.ruby.empty?).to eq(false)
    expect(gemfile_lock.ruby.engine_version).to eq("3.3.5")

    expect(gemfile_lock.bundler.version).to eq("2.3.4")
    expect(gemfile_lock.bundler.empty?).to eq(false)
  end

  it "captures jruby version" do
    gemfile_lock = LanguagePack::Helpers::GemfileLock.new(
      contents: <<~EOF
        GEM
          remote: https://rubygems.org/
          specs:
        PLATFORMS
          java
        RUBY VERSION
           ruby 2.5.7p001 (jruby 9.2.13.0)
      EOF
    )
    expect(gemfile_lock.ruby.ruby_version).to eq("2.5.7")
    expect(gemfile_lock.ruby.pre).to eq(nil)
    expect(gemfile_lock.ruby.engine).to eq(:jruby)
    expect(gemfile_lock.ruby.empty?).to eq(false)
    expect(gemfile_lock.ruby.engine_version).to eq("9.2.13.0")
  end

  it "is resiliant to gemfile.lock format changes" do
    gemfile_lock = LanguagePack::Helpers::GemfileLock.new(
      contents: <<~EOF
        GEM
          remote: https://rubygems.org/
          specs:
        # Pretend format change
        METADATA
          (jruby 9)
        PLATFORMS
          java
        RUBY VERSION
           ruby 2.5.7p001 (jruby 9.2.13.0)
      EOF
    )
    expect(gemfile_lock.ruby.ruby_version).to eq("2.5.7")
    expect(gemfile_lock.ruby.pre).to eq(nil)
    expect(gemfile_lock.ruby.engine).to eq(:jruby)
    expect(gemfile_lock.ruby.empty?).to eq(false)
    expect(gemfile_lock.ruby.engine_version).to eq("9.2.13.0")
  end

  it "handles RC dot syntax" do
    gemfile_lock = LanguagePack::Helpers::GemfileLock.new(
      contents: <<~EOF
        RUBY VERSION
           ruby 3.4.0.rc1
        BUNDLED WITH
           2.3.4
      EOF
    )
    expect(gemfile_lock.ruby.ruby_version).to eq("3.4.0")
    expect(gemfile_lock.ruby.pre).to eq("rc1")
    expect(gemfile_lock.ruby.engine).to eq(:ruby)
    expect(gemfile_lock.ruby.empty?).to eq(false)
    expect(gemfile_lock.ruby.engine_version).to eq("3.4.0")
  end

  it "handles pre without a number" do
    gemfile_lock = LanguagePack::Helpers::GemfileLock.new(
      contents: <<~EOF
        RUBY VERSION
           ruby 3.4.0.lol
        BUNDLED WITH
           2.3.4
      EOF
    )
    expect(gemfile_lock.ruby.ruby_version).to eq("3.4.0")
    expect(gemfile_lock.ruby.pre).to eq("lol")
    expect(gemfile_lock.ruby.engine).to eq(:ruby)
    expect(gemfile_lock.ruby.empty?).to eq(false)
    expect(gemfile_lock.ruby.engine_version).to eq("3.4.0")
  end

  it "handles preview dot syntax" do
    gemfile_lock = LanguagePack::Helpers::GemfileLock.new(
      contents: <<~EOF
        RUBY VERSION
           ruby 3.4.0.preview2
        BUNDLED WITH
           2.3.4
      EOF
    )
    expect(gemfile_lock.ruby.ruby_version).to eq("3.4.0")
    expect(gemfile_lock.ruby.pre).to eq("preview2")
    expect(gemfile_lock.ruby.engine).to eq(:ruby)
    expect(gemfile_lock.ruby.empty?).to eq(false)
    expect(gemfile_lock.ruby.engine_version).to eq("3.4.0")
  end

  it "handles Bundler 4 style" do
    gemfile_lock = LanguagePack::Helpers::GemfileLock.new(
      contents: <<~EOF
        RUBY VERSION
          ruby 3.4.0
        BUNDLED WITH
          2.3.4
      EOF
    )
    expect(gemfile_lock.ruby.ruby_version).to eq("3.4.0")
    expect(gemfile_lock.ruby.pre).to eq(nil)
    expect(gemfile_lock.ruby.engine).to eq(:ruby)
    expect(gemfile_lock.ruby.empty?).to eq(false)
    expect(gemfile_lock.ruby.engine_version).to eq("3.4.0")
  end
end
