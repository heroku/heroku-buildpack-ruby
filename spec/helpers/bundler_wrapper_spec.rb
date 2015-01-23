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

  it "detects windows gemfiles" do
    Hatchet::App.new("rails4_windows_mri193").in_directory do |dir|
      expect(@bundler.install.windows_gemfile_lock?).to be_true
    end
  end

  describe "when executing bundler" do
    before do
      @bundler.install
    end

    it "handles JRuby pre gemfiles" do
      Hatchet::App.new("jruby-minimal").in_directory do |dir|
        expect(@bundler.ruby_version).to eq("ruby-2.2.0-jruby-9.0.0.0.pre1")
      end
    end

    it "handles MRI patchlevel gemfiles" do
      Hatchet::App.new("mri_193_p547").in_directory do |dir|
        expect(@bundler.ruby_version).to eq("ruby-1.9.3-p547")
      end
    end
  end
end

