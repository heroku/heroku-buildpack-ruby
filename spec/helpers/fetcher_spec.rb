require 'spec_helper'

describe "Fetches" do
  it "bundler" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.touch("Gemfile.lock")

        fetcher = LanguagePack::Fetcher.new(LanguagePack::Base::VENDOR_URL)
        fetcher.fetch_untar("#{LanguagePack::Helpers::BundlerWrapper.new.dir_name}.tgz")
        expect(`ls bin`).to match("bundle")
      end
    end
  end
end
