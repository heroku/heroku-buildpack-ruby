require "spec_helper"

describe LanguagePack::Installers::HerokuRubyInstaller do
  def installer(report: HerokuBuildReport::GLOBAL)
    LanguagePack::Installers::HerokuRubyInstaller.new(
      multi_arch_stacks: ["heroku-24"],
      stack: "heroku-24",
      arch: "amd64",
      report: report
    )
  end

  def ruby_version
    LanguagePack::RubyVersion.bundle_platform_ruby(bundler_output: "ruby-3.1.7")
  end

  describe "#fetch_unpack" do
    it "should fetch and unpack mri" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          installer.fetch_unpack(ruby_version, dir)

          expect(File).to exist("bin/ruby")
        end
      end
    end
  end

  describe "#install" do
    it "should install ruby and setup binstubs" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          report = HerokuBuildReport.dev_null
          installer(report: report).install(ruby_version, "#{dir}/vendor/ruby")

          expect(File.symlink?("#{dir}/bin/ruby")).to be true
          expect(File.symlink?("#{dir}/bin/ruby.exe")).to be true
          expect(File).to exist("#{dir}/vendor/ruby/bin/ruby")

          expect(report.data["ruby_version"]).to eq("ruby-3.1.7")
          expect(report.data["ruby_version_engine"]).to eq(:ruby)
          expect(report.data["ruby_version_engine_version"]).to eq(report.data["ruby_version"].split("-").last)
          expect(report.data["ruby_version_major"]).to eq(3)
          expect(report.data["ruby_version_minor"]).to eq(1)
          expect(report.data["ruby_version_patch"]).to eq(7)
        end
      end
    end

    it "should report jruby correctly" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          report = HerokuBuildReport.dev_null

          LanguagePack::Installers::HerokuRubyInstaller.new(
            multi_arch_stacks: ["heroku-24"],
            stack: "heroku-24",
            arch: "arm64",
            report: report
          ).install(
            LanguagePack::RubyVersion.bundle_platform_ruby(bundler_output: "ruby-3.1.4-p0-jruby-9.4.9.0"),
            "#{dir}/vendor/ruby"
          )

          expect(report.data["ruby_version"]).to eq("ruby-3.1.4-jruby-9.4.9.0")
          expect(report.data["ruby_version_engine"]).to eq(:jruby)
          expect(report.data["ruby_version_engine_version"]).to eq("9.4.9.0")
          expect(report.data["ruby_version_major"]).to eq(3)
          expect(report.data["ruby_version_minor"]).to eq(1)
          expect(report.data["ruby_version_patch"]).to eq(4)
        end
      end
    end
  end
end
