require 'spec_helper'

describe "BundlerWrapper" do

  after(:each) do
    FileUtils.remove_entry_secure("tmp") if Dir.exist?("tmp")
  end

  it "detects windows gemfiles" do
    Hatchet::App.new("rails4_windows_mri193").in_directory do |dir|
      @bundler = LanguagePack::Helpers::BundlerWrapper.new(gemfile_path: "./Gemfile")
      expect(@bundler.windows_gemfile_lock?).to be_true
    end
  end
end

