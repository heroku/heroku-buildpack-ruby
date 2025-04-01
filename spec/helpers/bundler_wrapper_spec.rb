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

describe "Bundler version detection" do
  it "supports minor versions" do
    wrapper_klass = LanguagePack::Helpers::BundlerWrapper
    version = wrapper_klass.detect_bundler_version(contents: "BUNDLED WITH\n   1.17.3")
    expect(wrapper_klass::BLESSED_BUNDLER_VERSIONS.key?("1")).to be_truthy
    expect(version).to eq(wrapper_klass::BLESSED_BUNDLER_VERSIONS["1"])

    version = wrapper_klass.detect_bundler_version(contents: "BUNDLED WITH\n   2.2.7")
    expect(wrapper_klass::BLESSED_BUNDLER_VERSIONS.key?("2.3")).to be_truthy
    expect(version).to eq(wrapper_klass::BLESSED_BUNDLER_VERSIONS["2.3"])

    version = wrapper_klass.detect_bundler_version(contents: "BUNDLED WITH\n   2.3.7")
    expect(wrapper_klass::BLESSED_BUNDLER_VERSIONS.key?("2.3")).to be_truthy
    expect(version).to eq(wrapper_klass::BLESSED_BUNDLER_VERSIONS["2.3"])

    version = wrapper_klass.detect_bundler_version(contents: "BUNDLED WITH\n   2.4.7")
    expect(wrapper_klass::BLESSED_BUNDLER_VERSIONS.key?("2.4")).to be_truthy
    expect(version).to eq(wrapper_klass::BLESSED_BUNDLER_VERSIONS["2.4"])

    version = wrapper_klass.detect_bundler_version(contents: "BUNDLED WITH\n   2.5.7")
    expect(wrapper_klass::BLESSED_BUNDLER_VERSIONS.key?("2.5")).to be_truthy
    expect(version).to eq(wrapper_klass::BLESSED_BUNDLER_VERSIONS["2.5"])

    version = wrapper_klass.detect_bundler_version(contents: "BUNDLED WITH\n   2.6.7")
    expect(wrapper_klass::BLESSED_BUNDLER_VERSIONS.key?("2.6")).to be_truthy
    expect(version).to eq(wrapper_klass::BLESSED_BUNDLER_VERSIONS["2.6"])

    version = wrapper_klass.detect_bundler_version(contents: "BUNDLED WITH\n   2.999.7")
    expect(wrapper_klass::BLESSED_BUNDLER_VERSIONS.key?("2.6")).to be_truthy
    expect(version).to eq(wrapper_klass::BLESSED_BUNDLER_VERSIONS["2.6"])

    expect {
      wrapper_klass.detect_bundler_version(contents: "BUNDLED WITH\n   3.6.7")
    }.to raise_error(wrapper_klass::UnsupportedBundlerVersion)
  end
end

describe "Multiple platform detection" do
  it "reports true on bundler 2.2+" do
    Dir.mktmpdir do |dir|
      gemfile = Pathname(dir).join("Gemfile")
      lockfile = Pathname(dir).join("Gemfile.lock").tap {|p| p.write("BUNDLED WITH\n   2.5.7") }
      report = HerokuBuildReport.dev_null

      bundler = LanguagePack::Helpers::BundlerWrapper.new(
        gemfile_path: gemfile,
        report: report
      )
      expect(bundler.supports_multiple_platforms?).to be_truthy

      expect(report.data).to eq(
        {
          "bundled_with" => "2.5.7",
          "bundler_major" => "2",
          "bundler_minor" => "5",
          "bundler_patch" => "23",
          "bundler_version_installed" => "2.5.23",
        }
      )
    end
  end
end

describe "BundlerWrapper mutates rubyopt" do
  before(:each) do
    if ENV['RUBYOPT']
      @original_rubyopt = ENV['RUBYOPT']
      ENV['RUBYOPT'] = ENV['RUBYOPT'].sub('-rbundler/setup', '')
    end

    @bundler = LanguagePack::Helpers::BundlerWrapper.new
  end

  after(:each) do
    if ENV['RUBYOPT']
      ENV['RUBYOPT'] = @original_rubyopt
    end

    @bundler.clean
  end

  it "handles windows BUNDLED WITH" do
    Dir.mktmpdir do |dir|
      tmp_dir = Pathname(dir)
      FileUtils.cp_r(fixture_path("windows_lockfile/."), tmp_dir)

      tmp_gemfile_path = tmp_dir.join("Gemfile")
      tmp_gemfile_lock_path = tmp_dir.join("Gemfile.lock")

      expect(tmp_gemfile_lock_path.read).to match("BUNDLED")

      wrapper = LanguagePack::Helpers::BundlerWrapper.new(gemfile_path: tmp_gemfile_path )

      expect(wrapper.version).to eq(LanguagePack::Helpers::BundlerWrapper::BLESSED_BUNDLER_VERSIONS["2"])

      def wrapper.topic(*args); end # Silence output in tests
      wrapper.bundler_version_escape_valve!

      expect(tmp_gemfile_lock_path.read).to_not match("BUNDLED")
    end
  end

  it "detects windows gemfiles" do
    Hatchet::App.new("rails4_windows_mri193").in_directory_fork do |dir|
      require "bundler"
      Bundler.with_unbundled_env do
        expect(@bundler.install.windows_gemfile_lock?).to be_truthy
      end
    end
  end

  describe "when executing bundler" do
    it "handles JRuby pre gemfiles" do
      Hatchet::App.new("jruby-minimal").in_directory_fork do |dir|
        require "bundler"
        Bundler.with_unbundled_env do
          @bundler.install

          expect(@bundler.ruby_version).to eq("ruby-2.3.1-p0-jruby-9.1.7.0")
        end
      end
    end
  end
end
