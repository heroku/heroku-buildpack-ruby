require 'spec_helper'

describe "BundlerWrapper" do

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
    wrapper = LanguagePack::Helpers::BundlerWrapper.new(gemfile_path: fixture_path("windows_lockfile/Gemfile"))

    expect(wrapper.version).to eq(LanguagePack::Helpers::BundlerWrapper::BLESSED_BUNDLER_VERSIONS["2"])
  end

  it "detects windows gemfiles" do
    Hatchet::App.new("rails4_windows_mri193").in_directory_fork do |dir|
      expect(@bundler.install.windows_gemfile_lock?).to be_truthy
    end
  end

  describe "when executing bundler" do
    before do
      @bundler.install
    end

    it "handles apps with ruby versions locked in Gemfile.lock" do
      Hatchet::App.new("problem_gemfile_version").in_directory_fork do |dir|
        expect(@bundler.ruby_version).to eq("ruby-2.5.1-p0")

        ruby_version = LanguagePack::RubyVersion.new(@bundler.ruby_version, is_new: true)
        expect(ruby_version.version_for_download).to eq("ruby-2.5.1")
      end
    end

    it "handles JRuby pre gemfiles" do
      Hatchet::App.new("jruby-minimal").in_directory_fork do |dir|
        expect(@bundler.ruby_version).to eq("ruby-2.3.1-p0-jruby-9.1.7.0")
      end
    end

    it "handles MRI patchlevel gemfiles" do
      Hatchet::App.new("mri_193_p547").in_directory_fork do |dir|
        expect(@bundler.ruby_version).to eq("ruby-1.9.3-p547")
      end
    end

    it "handles app with output in their Gemfile" do
      Hatchet::App.new("problem_gemfile_version").in_directory_fork do |dir|
        run!(%{echo '\nputs "some output"\n' >> Gemfile})
        expect(@bundler.ruby_version).to eq("ruby-2.5.1-p0")
      end
    end
  end
end
