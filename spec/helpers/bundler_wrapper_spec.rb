require 'spec_helper'

describe "BundlerWrapper" do

  before(:each) do
    @bundler = LanguagePack::Helpers::BundlerWrapper.new
  end

  after(:each) do
    @bundler.clean
  end

  it "detects windows gemfiles" do
    Hatchet::App.new("rails4_windows_mri193").in_directory do |dir|
      expect(@bundler.install.windows_gemfile_lock?).to be_true
    end
  end
end

