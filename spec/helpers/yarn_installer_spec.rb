require 'spec_helper'

describe LanguagePack::Helpers::YarnInstaller do
  describe "#install" do

    it "should extract the yarn package" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          installer = LanguagePack::Helpers::YarnInstaller.new
          installer.install

          # webpacker gem checks for yarnpkg
          # https://github.com/rails/webpacker/blob/master/lib/install/bin/yarn.tt#L5
          expect(File.exist?("yarn-v#{installer.version}/bin/yarnpkg")).to be(true)
        end
      end
    end
  end
end
