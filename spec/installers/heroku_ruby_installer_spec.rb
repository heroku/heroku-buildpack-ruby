require "spec_helper"

describe LanguagePack::Installers::HerokuRubyInstaller do
  let(:installer)    { LanguagePack::Installers::HerokuRubyInstaller.new("cedar-14") }
  let(:ruby_version) { LanguagePack::RubyVersion.new("ruby-2.3.3") }

  describe "#fetch_unpack" do
    it "should fetch and unpack mri" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          installer.fetch_unpack(ruby_version, dir)

          expect(File).to exist("bin/ruby")
        end
      end
    end

    context "build rubies" do
      let(:ruby_version) { LanguagePack::RubyVersion.new("ruby-1.9.2") }

      it "should fetch and unpack the build ruby" do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            installer.fetch_unpack(ruby_version, dir, true)

            expect(File.read("lib/ruby/1.9.1/x86_64-linux/rbconfig.rb")).to include(%q{CONFIG["prefix"] = (TOPDIR || DESTDIR + "/tmp/ruby-1.9.2")})
            expect(File).to exist("bin/ruby")
          end
        end
      end

    end
  end

  describe "#install" do

    it "should install ruby and setup binstubs" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          installer.install(ruby_version, "#{dir}/vendor/ruby")

          expect(File.symlink?("#{dir}/bin/ruby")).to be true
          expect(File.symlink?("#{dir}/bin/ruby.exe")).to be true
          expect(File).to exist("#{dir}/vendor/ruby/bin/ruby")
        end
      end
    end

  end
end
