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

  def sort_hash(hash)
    hash.sort_by { |k, _| k.to_s }.to_h
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

  describe "ruby installation" do
    it "should install ruby and setup binstubs" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          report = HerokuBuildReport.dev_null
          installer(report: report).install(ruby_version, "#{dir}/vendor/ruby")

          expect(File.symlink?("#{dir}/bin/ruby")).to be true
          expect(File.symlink?("#{dir}/bin/ruby.exe")).to be true
          expect(File).to exist("#{dir}/vendor/ruby/bin/ruby")

          expected = {
            "ruby_version_engine" => :ruby,
            "ruby_version_full" => "3.1.7",
            "ruby_version_major_minor" => "3.1",
            "ruby_version_origin" => "Gemfile.lock",
            "ruby_version_unique" => "ruby-3.1.7"
          }

          expect(sort_hash(report.data)).to eq(sort_hash(expected))
        end
      end
    end

    it "should work with pre-release versions" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          report = HerokuBuildReport.dev_null
          installer(report: report).install(
            LanguagePack::RubyVersion.bundle_platform_ruby(bundler_output: "ruby-3.5.0.preview1"),
            "#{dir}/vendor/ruby"
          )

          expect(File.symlink?("#{dir}/bin/ruby")).to be true
          expect(File.symlink?("#{dir}/bin/ruby.exe")).to be true
          expect(File).to exist("#{dir}/vendor/ruby/bin/ruby")

          expected = {
            "ruby_version_engine" => :ruby,
            "ruby_version_major_minor" => "3.5",
            "ruby_version_full" => "3.5.0.preview1",
            "ruby_version_origin" => "Gemfile.lock",
            "ruby_version_unique" => "ruby-3.5.0.preview1"
          }

          expect(sort_hash(report.data)).to eq(sort_hash(expected))
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

          expected = {
            "ruby_version_engine" => :jruby,
            "jruby_version_full" => "9.4.9.0",
            "jruby_version_major_minor" => "9.4",
            "jruby_version_ruby_version" => "3.1.4",
            "ruby_version_origin" => "Gemfile.lock",
            "ruby_version_unique" => "ruby-3.1.4-jruby-9.4.9.0"
          }

          expect(sort_hash(report.data)).to eq(sort_hash(expected))
        end
      end
    end
  end
end
