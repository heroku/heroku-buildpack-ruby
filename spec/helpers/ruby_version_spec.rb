require 'spec_helper'

describe "RubyVersion" do
  before(:each) do
    @bundler = LanguagePack::Helpers::BundlerWrapper.new
  end

  after(:each) do
    @bundler.clean
  end

  it "correctly sets ruby version for bundler specified versions" do
    Hatchet::App.new("mri_193").in_directory do |dir|
      ruby_version   = LanguagePack::RubyVersion.new(@bundler.install, is_new: true)
      version_number = "1.9.3"
      version        = "ruby-#{version_number}"
      expect(ruby_version.version_without_patchlevel).to eq(version)
      expect(ruby_version.engine_version).to eq(version_number)
      expect(ruby_version.to_gemfile).to eq("ruby '#{version_number}'")
      expect(ruby_version.engine).to eq(:ruby)
    end
  end

  it "correctly sets default ruby versions" do
    Hatchet::App.new("default_ruby").in_directory do |dir|
      ruby_version   = LanguagePack::RubyVersion.new(@bundler.install, is_new: true)
      version_number = LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER
      version        = LanguagePack::RubyVersion::DEFAULT_VERSION
      expect(ruby_version.version_without_patchlevel).to eq(version)
      expect(ruby_version.engine_version).to eq(version_number)
      expect(ruby_version.to_gemfile).to eq("ruby '#{version_number}'")
      expect(ruby_version.engine).to eq(:ruby)
      expect(ruby_version.default?).to eq(true)
    end
  end

  it "correctly sets default legacy version" do
    Hatchet::App.new("default_ruby").in_directory do |dir|
      ruby_version   = LanguagePack::RubyVersion.new(@bundler.install, is_new: false)
      version_number = LanguagePack::RubyVersion::LEGACY_VERSION_NUMBER
      version        = LanguagePack::RubyVersion::LEGACY_VERSION
      expect(ruby_version.version_without_patchlevel).to eq(version)
      expect(ruby_version.engine_version).to eq(version_number)
      expect(ruby_version.to_gemfile).to eq("ruby '#{version_number}'")
      expect(ruby_version.engine).to eq(:ruby)
    end
  end

  it "detects Ruby 2.0.0" do
    Hatchet::App.new("mri_200").in_directory do |dir|
      ruby_version   = LanguagePack::RubyVersion.new(@bundler.install, is_new: true)
      version_number = "2.0.0"
      version        = "ruby-#{version_number}"
      expect(ruby_version.version_without_patchlevel).to eq(version)
      expect(ruby_version.engine_version).to eq(version_number)
      expect(ruby_version.to_gemfile).to eq("ruby '#{version_number}'")
      expect(ruby_version.engine).to eq(:ruby)
    end
  end


  it "detects non mri engines" do
    Hatchet::App.new("ruby_193_jruby_173").in_directory do |dir|
      ruby_version   = LanguagePack::RubyVersion.new(@bundler.install, is_new: true)
      version_number = "1.9.3"
      engine_version = "1.7.3"
      engine         = :jruby
      version        = "ruby-#{version_number}-#{engine}-#{engine_version}"
      to_gemfile     = "ruby '#{version_number}', :engine => '#{engine}', :engine_version => '#{engine_version}'"
      expect(ruby_version.version_without_patchlevel).to eq(version)
      expect(ruby_version.engine_version).to eq(engine_version)
      expect(ruby_version.to_gemfile).to eq(to_gemfile)
      expect(ruby_version.engine).to eq(engine)
    end
  end

  it "surfaces error message from bundler"  do
    bundle_error_msg = "Zomg der was a problem in da gemfile"
    error_klass      = LanguagePack::Helpers::BundlerWrapper::GemfileParseError
    Hatchet::App.new("bad_gemfile_on_platform").in_directory do |dir|
      @bundler       = LanguagePack::Helpers::BundlerWrapper.new()
      expect {LanguagePack::RubyVersion.new(@bundler)}.to raise_error(error_klass, /#{Regexp.escape(bundle_error_msg)}/)
    end
  end
end
