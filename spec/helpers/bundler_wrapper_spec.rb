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
end

