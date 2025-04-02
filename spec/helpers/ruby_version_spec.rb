require 'spec_helper'

describe "RubyVersion::ParsedVersion" do
  it "parses jruby" do
    parsed = LanguagePack::RubyVersion::ParsedVersion.new(
      from_bundler: "ruby-3.1.4-p0-jruby-9.4.9.0"
    )

    expect(parsed.version).to eq("3.1.4")
    expect(parsed.engine).to eq(:jruby)
    expect(parsed.engine_version).to eq("9.4.9.0")

    expect(parsed.major).to eq(3)
    expect(parsed.minor).to eq(1)
    expect(parsed.patch).to eq(4)
  end

  it "parses mri" do
    parsed = LanguagePack::RubyVersion::ParsedVersion.new(
      from_bundler: "ruby-3.4.2p28"
    )

    expect(parsed.version).to eq("3.4.2")
    expect(parsed.engine).to eq(:ruby)
    expect(parsed.engine_version).to eq("3.4.2")

    expect(parsed.major).to eq(3)
    expect(parsed.minor).to eq(4)
    expect(parsed.patch).to eq(2)
  end
end

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

    expect(ruby_version.version_for_download).to eq(version)
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
      require 'bundler'
      Bundler.with_unbundled_env do
        ruby_version   = LanguagePack::RubyVersion.new(@bundler.install.ruby_version, is_new: true)
        version_number = LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER
        version        = LanguagePack::RubyVersion::DEFAULT_VERSION
        expect(ruby_version.version_for_download).to eq(version)
        expect(ruby_version.engine_version).to eq(version_number)
        expect(ruby_version.to_gemfile).to eq("ruby '#{version_number}'")
        expect(ruby_version.engine).to eq(:ruby)
        expect(ruby_version.default?).to eq(true)
      end
    end
  end

  it "detects Ruby from Gemfile.lock" do
    Hatchet::App.new("default_ruby").in_directory_fork do |_|
      require 'bundler'
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
        expect(@bundler.install.ruby_version).to eq("ruby-3.2.3")
        expect(ruby_version.version_for_download).to eq(version)
        expect(ruby_version.engine_version).to eq(version_number)
        expect(ruby_version.engine).to eq(:ruby)
      end
    end
  end

  it "detects non mri engines" do
    Hatchet::App.new("default_ruby").in_directory_fork do |_|
      require 'bundler'
      dir = Pathname(Dir.pwd)
      Bundler.with_unbundled_env do
        dir.join("Gemfile").write(<<~EOF)
          source "https://rubygems.org"

          ruby '>3', engine: 'jruby', engine_version: '9.4.9.0'
        EOF
        dir.join("Gemfile.lock").write(<<~EOF)
          GEM
            remote: https://rubygems.org/
            specs:
              rake (13.2.1)

          PLATFORMS
            arm64-darwin-24
            ruby
            universal-java-21

          DEPENDENCIES
            rake

          RUBY VERSION
            ruby 3.1.4p0 (jruby 9.4.9.0)

          BUNDLED WITH
            2.6.6
        EOF

        ruby_version   = LanguagePack::RubyVersion.new(
          @bundler.install.ruby_version,
          is_new: true
        )
        version_number = "3.1.4"
        engine_version = "9.4.9.0"
        engine = :jruby

        expect(@bundler.install.ruby_version).to eq("ruby-3.1.4-p0-jruby-9.4.9.0")
        expect(ruby_version.version_for_download).to eq("ruby-#{version_number}-#{engine}-#{engine_version}")
        expect(ruby_version.engine_version).to eq(engine_version)
        expect(ruby_version.engine).to eq(engine)
      end
    end
  end
end
