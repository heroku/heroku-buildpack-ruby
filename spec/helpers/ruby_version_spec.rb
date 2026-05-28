require "spec_helper"

describe "RubyVersion" do
  it "knows the next logical version" do
    version_number = "2.5.0"
    ruby_version = LanguagePack::RubyVersion.default(last_version: version_number)
    version = "ruby-#{version_number}"

    expect(ruby_version.version_for_download).to eq(version)
    expect(ruby_version.next_logical_version).to eq("ruby-2.5.1")
    expect(ruby_version.next_logical_version).to eq("ruby-2.5.1")
    expect(ruby_version.next_logical_version(2)).to eq("ruby-2.5.2")
    expect(ruby_version.next_logical_version(20)).to eq("ruby-2.5.20")
    expect(ruby_version.bundler_directory).to eq("vendor/bundle/ruby/2.5.0")

    # Minor version
    expect(ruby_version.next_minor_version).to eq("ruby-2.6.0")
    expect(ruby_version.next_minor_version(2)).to eq("ruby-2.7.0")

    # Major Version
    expect(ruby_version.next_major_version).to eq("ruby-3.0.0")
    expect(ruby_version.next_major_version(2)).to eq("ruby-4.0.0")
  end

  it "correctly sets default ruby versions" do
    Hatchet::App.new("default_ruby").in_directory_fork do |_dir|
      dir = Pathname(Dir.pwd)
      ruby_version = LanguagePack::RubyVersion.from_gemfile_lock(
        ruby: LanguagePack::Helpers::GemfileLock.new(
          contents: dir.join("Gemfile.lock").read
        ).ruby
      )
      version = LanguagePack::RubyVersion::DEFAULT_VERSION
      version_number = LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER
      major, minor, _ = version_number.split(".")
      expect(ruby_version.version_for_download).to eq(version)
      expect(ruby_version.engine_version).to eq(version_number)
      expect(ruby_version.to_gemfile).to eq("ruby '#{version_number}'")
      expect(ruby_version.engine).to eq(:ruby)
      expect(ruby_version.default?).to eq(true)
      expect(ruby_version.bundler_directory).to eq("vendor/bundle/ruby/#{major}.#{minor}.0")
    end
  end

  it "detects Ruby from Gemfile.lock" do
    Hatchet::App.new("default_ruby").in_directory_fork do |_|
      dir = Pathname(Dir.pwd)
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

      version_number = "3.2.3"
      version = "ruby-#{version_number}"
      ruby_version = LanguagePack::RubyVersion.from_gemfile_lock(
        ruby: LanguagePack::Helpers::GemfileLock.new(
          contents: dir.join("Gemfile.lock").read
        ).ruby
      )
      expect(ruby_version.version_for_download).to eq(version)
      expect(ruby_version.engine_version).to eq(version_number)
      expect(ruby_version.engine).to eq(:ruby)
    end
  end

  it "detects RC Ruby from Gemfile.lock" do
    Hatchet::App.new("default_ruby").in_directory_fork do |_|
      dir = Pathname(Dir.pwd)
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
           ruby 3.2.3.rc1

        BUNDLED WITH
           2.4.19
      EOF

      version_number = "3.2.3"
      version = "ruby-#{version_number}.rc1"

      # Shadow logic validation
      ruby_version = LanguagePack::RubyVersion.from_gemfile_lock(
        ruby: LanguagePack::Helpers::GemfileLock.new(
          contents: dir.join("Gemfile.lock").read
        ).ruby
      )
      expect(ruby_version.version_for_download).to eq(version)
      expect(ruby_version.engine_version).to eq(version_number)
      expect(ruby_version.engine).to eq(:ruby)
    end
  end

  it "detects pre versions that do not end in numbers" do
    Hatchet::App.new("default_ruby").in_directory_fork do |_|
      dir = Pathname(Dir.pwd)
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
           ruby 3.2.3.lol

        BUNDLED WITH
           2.4.19
      EOF

      version_number = "3.2.3"
      version = "ruby-#{version_number}.lol"

      ruby_version = LanguagePack::RubyVersion.from_gemfile_lock(
        ruby: LanguagePack::Helpers::GemfileLock.new(
          contents: dir.join("Gemfile.lock").read
        ).ruby
      )
      expect(ruby_version.version_for_download).to eq(version)
      expect(ruby_version.engine_version).to eq(version_number)
      expect(ruby_version.engine).to eq(:ruby)
      expect(ruby_version.bundler_directory).to eq("vendor/bundle/ruby/3.2.0")
    end
  end

  it "detects non mri engines" do
    Hatchet::App.new("default_ruby").in_directory_fork do |_|
      dir = Pathname(Dir.pwd)
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

      version_number = "2.6.8"
      engine_version = "9.3.6.0"
      engine = :jruby

      ruby_version = LanguagePack::RubyVersion.from_gemfile_lock(
        ruby: LanguagePack::Helpers::GemfileLock.new(
          contents: dir.join("Gemfile.lock").read
        ).ruby
      )
      expect(ruby_version.version_for_download).to eq("ruby-#{version_number}-#{engine}-#{engine_version}")
      expect(ruby_version.engine_version).to eq(engine_version)
      expect(ruby_version.engine).to eq(engine)
      expect(ruby_version.bundler_directory).to eq("vendor/bundle/jruby/2.6.0")
    end
  end
end

describe "get_ruby_version .ruby-version comparison" do
  def gemfile_lock_with_ruby(version)
    LanguagePack::Helpers::GemfileLock.new(
      report: HerokuBuildReport.dev_null,
      contents: <<~EOF
        RUBY VERSION
           ruby #{version}
        BUNDLED WITH
           2.5.23
      EOF
    )
  end

  def gemfile_lock_default
    LanguagePack::Helpers::GemfileLock.new(
      report: HerokuBuildReport.dev_null,
      contents: <<~EOF
        BUNDLED WITH
           2.5.23
      EOF
    )
  end

  def dot_ruby_version_result(version)
    LanguagePack::Helpers::DotRubyVersionFile.new(contents: version).call
  end

  def get_ruby_version(gemfile_lock:, dot_ruby_version_result: nil)
    report = HerokuBuildReport.dev_null
    Dir.mktmpdir do |dir|
      metadata = LanguagePack::Metadata.new(cache_path: dir)
      LanguagePack::Ruby.get_ruby_version(
        metadata: metadata,
        gemfile_lock: gemfile_lock,
        dot_ruby_version_result: dot_ruby_version_result,
        report: report
      )
    end
    report
  end

  it "sets no comparison keys when .ruby-version is absent" do
    report = get_ruby_version(gemfile_lock: gemfile_lock_with_ruby("3.4.2"))

    expect(report.data).not_to have_key("dot_ruby_version.version")
    expect(report.data).not_to have_key("dot_ruby_version.vs_gemfile_lock")
  end

  it "sets no comparison keys when .ruby-version is unparseable" do
    result = dot_ruby_version_result("not-a-version")
    report = get_ruby_version(
      gemfile_lock: gemfile_lock_with_ruby("3.4.2"),
      dot_ruby_version_result: result
    )

    expect(result.ruby_version).to be_nil
    expect(report.data).not_to have_key("dot_ruby_version.version")
    expect(report.data).not_to have_key("dot_ruby_version.vs_gemfile_lock")
  end

  it "reports match when versions are equal" do
    report = get_ruby_version(
      gemfile_lock: gemfile_lock_with_ruby("3.4.2"),
      dot_ruby_version_result: dot_ruby_version_result("3.4.2")
    )

    expect(report.data["dot_ruby_version.version"]).to eq("3.4.2")
    expect(report.data["dot_ruby_version.vs_gemfile_lock"]).to eq("match")
  end

  it "reports dot_ruby_version_higher when .ruby-version is newer" do
    report = get_ruby_version(
      gemfile_lock: gemfile_lock_with_ruby("3.4.2"),
      dot_ruby_version_result: dot_ruby_version_result("3.5.0")
    )

    expect(report.data["dot_ruby_version.version"]).to eq("3.5.0")
    expect(report.data["dot_ruby_version.vs_gemfile_lock"]).to eq("dot_ruby_version_higher")
  end

  it "reports gemfile_lock_higher when Gemfile.lock is newer" do
    report = get_ruby_version(
      gemfile_lock: gemfile_lock_with_ruby("3.4.2"),
      dot_ruby_version_result: dot_ruby_version_result("3.3.0")
    )

    expect(report.data["dot_ruby_version.version"]).to eq("3.3.0")
    expect(report.data["dot_ruby_version.vs_gemfile_lock"]).to eq("gemfile_lock_higher")
  end

  it "sets version but skips comparison when Gemfile.lock has no ruby version" do
    report = get_ruby_version(
      gemfile_lock: gemfile_lock_default,
      dot_ruby_version_result: dot_ruby_version_result("3.4.2")
    )

    expect(report.data["dot_ruby_version.version"]).to eq("3.4.2")
    expect(report.data).not_to have_key("dot_ruby_version.vs_gemfile_lock")
  end
end
