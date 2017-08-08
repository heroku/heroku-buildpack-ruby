require "spec_helper"

describe LanguagePack::Installers::RbxInstaller do
  let(:installer)    { LanguagePack::Installers::RbxInstaller.new("cedar-14") }
  let(:ruby_version) { LanguagePack::RubyVersion.new("ruby-2.3.1-rbx-3.69") }

  describe "#fetch_unpack" do

    it "should fetch and unpack rbx" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          installer.fetch_unpack(ruby_version, dir)

          expect(File).to exist("bin/ruby")
        end
      end
    end

  end
end
