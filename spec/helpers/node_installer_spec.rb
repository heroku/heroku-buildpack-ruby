require 'spec_helper'

describe LanguagePack::Helpers::NodeInstaller do
  describe "#install" do
    it "should extract a node binary" do
      installer = LanguagePack::Helpers::NodeInstaller.new
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          installer.install

          expect(File.exist?("node")).to be(true)
        end
      end
    end
  end
end
