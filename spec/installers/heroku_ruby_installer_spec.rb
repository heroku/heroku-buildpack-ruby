require "spec_helper"

describe LanguagePack::Installers::HerokuRubyInstaller do
  def installer(report: HerokuBuildReport::GLOBAL)
    LanguagePack::Installers::HerokuRubyInstaller.new(
      multi_arch_stacks: [],
      stack: "cedar-14",
      arch: nil,
      report: report
    )
  end

  def ruby_version
    LanguagePack::RubyVersion.new("ruby-2.3.3")
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

          expect(report.data["ruby.version"]).to eq("2.3.3")
          expect(report.data["ruby.engine"]).to eq(:ruby)
          expect(report.data["ruby.engine.version"]).to eq(report.data["ruby.version"])
          expect(report.data["ruby.major"]).to eq(2)
          expect(report.data["ruby.minor"]).to eq(3)
          expect(report.data["ruby.patch"]).to eq(3)
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
            LanguagePack::RubyVersion.new("ruby-3.1.4-p0-jruby-9.4.9.0"),
            "#{dir}/vendor/ruby"
          )

          expect(report.data["ruby.version"]).to eq("3.1.4")
          expect(report.data["ruby.engine"]).to eq(:jruby)
          expect(report.data["ruby.engine.version"]).to eq("9.4.9.0")
          expect(report.data["ruby.major"]).to eq(3)
          expect(report.data["ruby.minor"]).to eq(1)
          expect(report.data["ruby.patch"]).to eq(4)
        end
      end
    end
  end
end
