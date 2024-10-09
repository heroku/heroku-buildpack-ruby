require 'spec_helper'

describe LanguagePack::Helpers::NodeInstaller do
  describe "#install" do
    LanguagePack::Base::KNOWN_ARCHITECTURES.each do |arch|
      it "should extract a node binary on #{arch}" do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            installer = LanguagePack::Helpers::NodeInstaller.new(arch: "arm64")
            installer.install

            expect(File.exist?("node")).to be(true)
          end
        end
      end
    end
  end
end
