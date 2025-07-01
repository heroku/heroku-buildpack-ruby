require 'spec_helper'

describe "Fetches" do
  LanguagePack::Helpers::BundlerWrapper::BLESSED_BUNDLER_VERSIONS.each do |_, version|
    it "bundler #{version}" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          lockfile = Pathname("Gemfile.lock")
          FileUtils.touch(lockfile)
          lockfile.write("BUNDLED WITH\n   #{version}")

          fetcher = LanguagePack::Fetcher.new(LanguagePack::Base::VENDOR_URL)
          fetcher.fetch_untar("bundler/#{LanguagePack::Helpers::BundlerWrapper.new.dir_name}.tgz")

          expect(run!("ls bin")).to match("bundle")
        end
      end
    end
  end
end
