require 'spec_helper'

describe "RubyVersion" do
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

  it "knows the next logical version" do
    version_number = "2.5.0"
    ruby_version   = LanguagePack::RubyVersion.new("ruby-#{version_number}-p0", is_new: true)
    version        = "ruby-#{version_number}"

    expect(ruby_version.version_without_patchlevel).to eq(version)
    expect(ruby_version.next_logical_version).to eq("ruby-2.5.1")
    expect(ruby_version.next_logical_version).to eq("ruby-2.5.1")
    expect(ruby_version.next_logical_version(2)).to eq("ruby-2.5.2")
    expect(ruby_version.next_logical_version(20)).to eq("ruby-2.5.20")

    # Minor version
    expect(ruby_version.next_minor_version).to eq("ruby-2.6.0")
    expect(ruby_version.next_minor_version(2)).to eq("ruby-2.7.0")

    # Major Version
    expect(ruby_version.next_major_version).to eq("ruby-3.0.0")
    expect(ruby_version.next_major_version(2)).to eq("ruby-4.0.0")
  end

  it "does not include patchlevels when the patchlevel is negative for download" do
    ruby_version = LanguagePack::RubyVersion.new("ruby-2.0.0-p-1")
    expect(ruby_version.version_for_download).to eq("ruby-2.0.0")

    ruby_version = LanguagePack::RubyVersion.new("ruby-2.4.0-p-1")
    expect(ruby_version.version_for_download).to eq("ruby-2.4.0")
  end

  it "detects Ruby 2.6.0, 2.6.1 and 2.6.2 as needing a warning" do
    ruby_version = LanguagePack::RubyVersion.new("ruby-2.6.0")
    expect(ruby_version.warn_ruby_26_bundler?).to be true
    ruby_version = LanguagePack::RubyVersion.new("ruby-2.6.1")
    expect(ruby_version.warn_ruby_26_bundler?).to be true
    ruby_version = LanguagePack::RubyVersion.new("ruby-2.6.2")
    expect(ruby_version.warn_ruby_26_bundler?).to be true

    ruby_version = LanguagePack::RubyVersion.new("ruby-2.6.3")
    expect(ruby_version.warn_ruby_26_bundler?).to be false
    ruby_version = LanguagePack::RubyVersion.new("ruby-2.5.3")
    expect(ruby_version.warn_ruby_26_bundler?).to be false
    ruby_version = LanguagePack::RubyVersion.new("ruby-2.7.1")
    expect(ruby_version.warn_ruby_26_bundler?).to be false
  end

  it "correctly sets default ruby versions" do
    Hatchet::App.new("default_ruby").in_directory_fork do |dir|
      Bundler.with_unbundled_env do
        ruby_version   = LanguagePack::RubyVersion.new(@bundler.install.ruby_version, is_new: true)
        version_number = LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER
        version        = LanguagePack::RubyVersion::DEFAULT_VERSION
        expect(ruby_version.version_without_patchlevel).to eq(version)
        expect(ruby_version.engine_version).to eq(version_number)
        expect(ruby_version.to_gemfile).to eq("ruby '#{version_number}'")
        expect(ruby_version.engine).to eq(:ruby)
        expect(ruby_version.default?).to eq(true)
      end
    end
  end

  it "detects Ruby from Gemfile.lock" do
    Hatchet::App.new("default_ruby").in_directory_fork do |_|
      dir = Pathname(Dir.pwd)
      Bundler.with_unbundled_env do
        dir.join("Gemfile").write(<<~EOF)
          source "https://rubygems.org"

          gem 'rake'
          ruby '3.2.3'
        EOF
        dir.join("Gemfile.lock").write(<<~EOF)
          GEM
            remote: https://rubygems.org/
            specs:
              rake (13.2.1)

          PLATFORMS
            arm64-darwin-22
            ruby
            x86_64-linux

          DEPENDENCIES
            rake

          RUBY VERSION
            ruby 3.2.3p157

          BUNDLED WITH
            2.4.19
        EOF

        ruby_version   = LanguagePack::RubyVersion.new(@bundler.install.ruby_version, is_new: true)
        version_number = "3.2.3"
        version        = "ruby-#{version_number}"
        expect(ruby_version.version_without_patchlevel).to eq(version)
        expect(ruby_version.engine_version).to eq(version_number)
        expect(ruby_version.engine).to eq(:ruby)
      end
    end
  end

  it "detects non mri engines" do
    Hatchet::App.new("default_ruby").in_directory_fork do |_|
      dir = Pathname(Dir.pwd)
      Bundler.with_unbundled_env do
        dir.join("Gemfile").write(<<~EOF)
          source "https://rubygems.org"

          ruby '2.6.8', engine: 'jruby', engine_version: '9.3.6.0'
        EOF
        dir.join("Gemfile.lock").write(<<~EOF)
          GEM
            remote: https://rubygems.org/
            specs:
          PLATFORMS
            java

          DEPENDENCIES

          RUBY VERSION
            ruby 2.6.8p001 (jruby 9.3.6.0)

          BUNDLED WITH
            2.3.25
        EOF

        ruby_version   = LanguagePack::RubyVersion.new(
          @bundler.install.ruby_version,
          is_new: true
        )
        version_number = "2.6.8"
        engine_version = "9.3.6.0"
        engine = :jruby
        expect(ruby_version.version_without_patchlevel).to eq("ruby-#{version_number}-#{engine}-#{engine_version}")
        expect(ruby_version.engine_version).to eq(engine_version)
        expect(ruby_version.engine).to eq(engine)
      end
    end
  end
end
