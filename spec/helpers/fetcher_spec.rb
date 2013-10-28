require 'spec_helper'

describe "Fetches" do

  it "bundler" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        fetcher = LanguagePack::Fetcher.new(LanguagePack::Base::VENDOR_URL)
        fetcher.fetch_untar("#{LanguagePack::Ruby::BUNDLER_GEM_PATH}.tgz")
        expect(`ls bin`).to match("bundle")
      end
    end
  end
end

