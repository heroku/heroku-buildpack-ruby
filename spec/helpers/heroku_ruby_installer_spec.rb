require "spec_helper"

describe LanguagePack::Installers::HerokuRubyInstaller do
  def installer(app_path:, report: HerokuBuildReport::GLOBAL, env: {})
    LanguagePack::Installers::HerokuRubyInstaller.new(
      multi_arch_stacks: ["heroku-24"],
      stack: "heroku-24",
      arch: "amd64",
      app_path: app_path,
      report: report,
      env: env
    )
  end

  def sort_hash(hash)
    hash.sort_by { |k, _| k.to_s }.to_h
  end

  def ruby_version
    LanguagePack::RubyVersion.default(last_version: "3.1.7")
  end

  describe "#fetch_unpack" do
    it "should fetch and unpack mri" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          installer(app_path: dir).fetch_unpack(ruby_version, dir)

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
          installer(app_path: Pathname(dir).expand_path, report: report).install(ruby_version, "#{dir}/vendor/ruby")

          expect(File.symlink?("#{dir}/bin/ruby")).to be true
          expect(File.symlink?("#{dir}/bin/ruby.exe")).to be true
          expect(File).to exist("#{dir}/vendor/ruby/bin/ruby")

          expect(File.readlink("#{dir}/bin/ruby")).to eq("../vendor/ruby/bin/ruby")

          expected = {
            "ruby_version_engine" => :ruby,
            "ruby_version_full" => "3.1.7",
            "ruby_version_major_minor" => "3.1",
            "ruby_version_origin" => "default",
            "ruby_version_unique" => "ruby-3.1.7"
          }

          expect(sort_hash(report.data)).to eq(sort_hash(expected))
        end
      end
    end

    it "should work with pre-release versions" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          dir = Pathname(dir).expand_path
          report = HerokuBuildReport.dev_null
          env = { "PATH" => "priorpath" }
          gemfile_lock = LanguagePack::Helpers::GemfileLock.new(report: report, contents: <<~EOF)
            RUBY VERSION
               ruby 3.5.0.preview1
          EOF
          installer(app_path: dir, report: report, env: env).install(
            LanguagePack::RubyVersion.from_gemfile_lock(ruby: gemfile_lock.ruby),
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
          expect(env).to eq({ "PATH" => "#{dir.join("vendor/ruby/bin")}:priorpath" })
        end
      end
    end

    it "should report jruby correctly" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          dir = Pathname(dir).expand_path
          report = HerokuBuildReport.dev_null
          gemfile_lock = LanguagePack::Helpers::GemfileLock.new(report: report, contents: <<~EOF)
            RUBY VERSION
               ruby 3.1.4p001 (jruby 9.4.9.0)
          EOF

          env = { "PATH" => "priorpath" }

          LanguagePack::Installers::HerokuRubyInstaller.new(
            multi_arch_stacks: ["heroku-24"],
            stack: "heroku-24",
            arch: "arm64",
            app_path: dir,
            report: report,
            env: env
          ).install(
            LanguagePack::RubyVersion.from_gemfile_lock(ruby: gemfile_lock.ruby),
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

          expect(env).to eq({ "JRUBY_OPTS" => nil, "PATH" => "#{dir.join("vendor/ruby/bin")}:priorpath" })
        end
      end
    end
  end
end
