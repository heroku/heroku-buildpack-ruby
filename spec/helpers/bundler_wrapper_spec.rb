require 'spec_helper'

describe "BundlerWrapper" do

  before(:each) do
    if ENV['RUBYOPT']
      @original_rubyopt = ENV['RUBYOPT']
      ENV['RUBYOPT'] = ENV['RUBYOPT'].sub('-rbundler/setup', '')
    end

    @bundler = LanguagePack::Helpers::BundlerWrapper.new
  end

  after(:each) do
    if ENV['RUBYOPT']
      ENV['RUBYOPT'] = @original_rubyopt
    end

    @bundler.clean
  end

  it "handles windows BUNDLED WITH" do
    Dir.mktmpdir do |dir|
      tmp_dir = Pathname(dir)
      FileUtils.cp_r(fixture_path("windows_lockfile/."), tmp_dir)

      tmp_gemfile_path = tmp_dir.join("Gemfile")
      tmp_gemfile_lock_path = tmp_dir.join("Gemfile.lock")

      expect(tmp_gemfile_lock_path.read).to match("BUNDLED")

      wrapper = LanguagePack::Helpers::BundlerWrapper.new(gemfile_path: tmp_gemfile_path )

      expect(wrapper.version).to eq(LanguagePack::Helpers::BundlerWrapper::BLESSED_BUNDLER_VERSIONS["2"])

      def wrapper.topic(*args); end # Silence output in tests
      wrapper.bundler_version_escape_valve!

      expect(tmp_gemfile_lock_path.read).to_not match("BUNDLED")
    end
  end

  it "detects windows gemfiles" do
    Hatchet::App.new("rails4_windows_mri193").in_directory_fork do |dir|
      Bundler.with_unbundled_env do
        expect(@bundler.install.windows_gemfile_lock?).to be_truthy
      end
    end
  end

  describe "when executing bundler" do
    it "handles apps with ruby versions locked in Gemfile.lock" do
      Hatchet::App.new("problem_gemfile_version").in_directory_fork do |dir|
        Bundler.with_unbundled_env do
          @bundler.install

          expect(@bundler.ruby_version).to eq("ruby-2.5.1-p0")

          ruby_version = LanguagePack::RubyVersion.new(@bundler.ruby_version, is_new: true)
          expect(ruby_version.version_for_download).to eq("ruby-2.5.1")
        end
      end
    end

    it "handles JRuby pre gemfiles" do
      Hatchet::App.new("jruby-minimal").in_directory_fork do |dir|
        Bundler.with_unbundled_env do
          @bundler.install

          expect(@bundler.ruby_version).to eq("ruby-2.3.1-p0-jruby-9.1.7.0")
        end
      end
    end

    it "handles app with output in their Gemfile" do
      Hatchet::App.new("problem_gemfile_version").in_directory_fork do |dir|
        Bundler.with_unbundled_env do
          @bundler.install

          run!(%{echo '\nputs "some output"\n' >> Gemfile})
          expect(@bundler.ruby_version).to eq("ruby-2.5.1-p0")
        end
      end
    end
  end
end
