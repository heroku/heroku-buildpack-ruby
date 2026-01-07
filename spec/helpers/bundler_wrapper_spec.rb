require 'spec_helper'

describe "Bundle platform conversion" do
  it "converts `bundle platform --ruby` for prerelease versions" do
    actual = LanguagePack::Helpers::BundlerWrapper.platform_to_version("ruby 3.3.0.preview2")
    expect(actual).to eq("ruby-3.3.0.preview2")
  end

  it "converts `bundle platform --ruby` for released versions" do
    actual = LanguagePack::Helpers::BundlerWrapper.platform_to_version("ruby 3.1.4")
    expect(actual).to eq("ruby-3.1.4")
  end
end

describe "Multiple platform detection" do
  it "reports true on bundler 2.2+" do
    Dir.mktmpdir do |dir|
      gemfile = Pathname(dir).join("Gemfile")
      report = HerokuBuildReport.dev_null

      LanguagePack::Helpers::BundlerWrapper.new(
        bundler_path: Dir.mktmpdir,
        bundler_version: "2.5.7",
        gemfile_path: gemfile,
        report: report
      )
      expect(report.data).to eq(
        {
          "ruby.dot_ruby_version" => nil,
          "bundler.major" => "2",
          "bundler.minor" => "5",
          "bundler.patch" => "7",
          "bundler.version_installed" => "2.5.7",
        }
      )
    end
  end
end

describe "BundlerWrapper" do
  it "handles windows BUNDLED WITH" do
    Dir.mktmpdir do |dir|
      tmp_dir = Pathname(dir)
      FileUtils.cp_r(fixture_path("windows_lockfile/."), tmp_dir)

      tmp_gemfile_path = tmp_dir.join("Gemfile")
      tmp_gemfile_lock_path = tmp_dir.join("Gemfile.lock")

      expect(tmp_gemfile_lock_path.read).to match("BUNDLED")

      gemfile_lock = LanguagePack::Helpers::GemfileLock.new(contents: tmp_gemfile_lock_path.read)
      wrapper = LanguagePack::Helpers::BundlerWrapper.new(
        bundler_path: Dir.mktmpdir,
        bundler_version: gemfile_lock.bundler.version,
        gemfile_path: tmp_gemfile_path
      )

      expect(wrapper.version).to eq("2.0.2")
    end
  end
end
