# frozen_string_literal: true

require 'language_pack/fetcher'

# This class is responsible for installing and maintaining a
# reference to bundler. It contains access to bundler internals
# that are used to introspect a project such as detecting presence
# of gems and their versions.
#
# Example:
#
#   bundler = LanguagePack::Helpers::BundlerWrapper.new
#   bundler.install
#   bundler.version                 => "1.15.2"
#   bundler.dir_name                => "bundler-1.15.2"
#   bundler.has_gem?("railties")    => true
#   bundler.gem_version("railties") => "5.2.2"
#   bundler.clean
#
# Also used to determine the version of Ruby that a project is using
# based on `bundle platform --ruby`
#
#   bundler.ruby_version # => "ruby-2.5.1"
#   bundler.clean
#
# IMPORTANT: Calling `BundlerWrapper#install` on this class mutates the environment variable
# ENV['BUNDLE_GEMFILE']. If you're calling in a test context (or anything outside)
# of an isolated dyno, you must call `BundlerWrapper#clean`. To reset the environment
# variable:
#
#   bundler = LanguagePack::Helpers::BundlerWrapper.new
#   bundler.install
#   bundler.clean # <========== IMPORTANT =============
#
class LanguagePack::Helpers::BundlerWrapper
  include LanguagePack::ShellHelpers

  BLESSED_BUNDLER_VERSIONS = {}
  # Heroku-22's oldest Ruby version is 3.1
  BLESSED_BUNDLER_VERSIONS["2.3"] = "2.3.25"
  BLESSED_BUNDLER_VERSIONS["2.4"] = "2.4.22"
  BLESSED_BUNDLER_VERSIONS["2.5"] = "2.5.23"
  BLESSED_BUNDLER_VERSIONS["2.6"] = "2.6.2"

  DEFAULT_VERSION = BLESSED_BUNDLER_VERSIONS["2.3"]

  # Convert arbitrary `<Major>.<Minor>.x` versions
  BLESSED_BUNDLER_VERSIONS.default_proc = Proc.new do |hash, key|
    case Gem::Version.new(key).segments.first
    when 2
      if Gem::Version.new(key) > Gem::Version.new("2.6")
        hash["2.6"]
      elsif Gem::Version.new(key) < Gem::Version.new("2.3")
        hash["2.3"]
      else
        raise UnsupportedBundlerVersion.new(hash, key)
      end
    else
      raise UnsupportedBundlerVersion.new(hash, key)
    end
  end

  def self.detect_bundler_version(contents: , bundled_with: contents.match(BUNDLED_WITH_REGEX))
    if bundled_with
      major = bundled_with[:major]
      minor = bundled_with[:minor]
      version = BLESSED_BUNDLER_VERSIONS["#{major}.#{minor}"]
      version
    else
      DEFAULT_VERSION
    end
  end

  BUNDLED_WITH_REGEX = /^BUNDLED WITH$(\r?\n)   (?<version>(?<major>\d+)\.(?<minor>\d+)\.\d+)/m

  class GemfileParseError < BuildpackError
    def initialize(error)
      msg = String.new("There was an error parsing your Gemfile, we cannot continue\n")
      msg << error
      super msg
    end
  end

  class UnsupportedBundlerVersion < BuildpackError
    def initialize(version_hash, major_minor)
      msg = String.new("Your Gemfile.lock indicates you need bundler `#{major_minor}.x`\n")
      msg << "which is not currently supported. You can deploy with bundler version:\n"
      version_hash.keys.each do |v|
        msg << "  - `#{v}.x`\n"
      end
      msg << "\nTo use another version of bundler, update your `Gemfile.lock` to point\n"
      msg << "to a supported version. For example:\n"
      msg << "\n"
      msg << "```\n"
      msg << "BUNDLED WITH\n"
      msg << "   #{DEFAULT_VERSION}\n"
      msg << "```\n"
      super msg
    end
  end

  attr_reader :bundler_path

  def initialize(options = {})
    @report               = options[:report] || HerokuBuildReport::GLOBAL
    @bundler_tmp          = Pathname.new(Dir.mktmpdir)
    @fetcher              = options[:fetcher]      || LanguagePack::Fetcher.new(LanguagePack::Base::VENDOR_URL) # coupling
    @gemfile_path         = options[:gemfile_path] || Pathname.new("./Gemfile")
    @gemfile_lock_path    = Pathname.new("#{@gemfile_path}.lock")

    contents = @gemfile_lock_path.read(mode: "rt")
    bundled_with = contents.match(BUNDLED_WITH_REGEX)
    dot_ruby_version_file = @gemfile_lock_path.join("..").join(".ruby-version")
    @report.capture(
      "bundler.bundled_with" => bundled_with&.[]("version") || "empty",
      # We use this bundler class to detect the Requested ruby version from the Gemfile.lock
      # Rails 8 stopped generating `RUBY VERSION` in the Gemfile.lock and started generating
      # a `.ruby-version` file. This will observe the formats to help guide implementation
      # decisions
      "ruby.dot_ruby_version" => dot_ruby_version_file.exist? ? dot_ruby_version_file.read&.strip : nil
    )
    @version = self.class.detect_bundler_version(
      contents: contents,
      bundled_with: bundled_with
    )
    parts = @version.split(".")
    @report.capture(
      "bundler.version_installed" => @version,
      "bundler.major" => parts&.shift,
      "bundler.minor" => parts&.shift,
      "bundler.patch" => parts&.shift
    )
    @dir_name = "bundler-#{@version}"

    @bundler_path         = options[:bundler_path] || @bundler_tmp.join(@dir_name)
    @bundler_tar          = options[:bundler_tar]  || "bundler/#{@dir_name}.tgz"
    @orig_bundle_gemfile  = ENV['BUNDLE_GEMFILE']
    @path                 = Pathname.new("#{@bundler_path}/gems/#{@dir_name}/lib")
  end

  def install
    ENV['BUNDLE_GEMFILE'] = @gemfile_path.to_s

    fetch_bundler
    $LOAD_PATH << @path
    require "bundler"
    self
  end

  def clean
    ENV['BUNDLE_GEMFILE'] = @orig_bundle_gemfile
    @bundler_tmp.rmtree if @bundler_tmp.directory?
  end

  def has_gem?(name)
    specs.key?(name)
  end

  def gem_version(name)
    if spec = specs[name]
      spec.version
    end
  end

  # detects whether the Gemfile.lock contains the Windows platform
  # @return [Boolean] true if the Gemfile.lock was created on Windows
  def windows_gemfile_lock?
    platforms.detect do |platform|
      /mingw|mswin/.match(platform.os) if platform.is_a?(Gem::Platform)
    end
  end

  def specs
    @specs ||= lockfile_parser.specs.each_with_object({}) {|spec, hash| hash[spec.name] = spec }
  end

  def platforms
    @platforms ||= lockfile_parser.platforms
  end

  def version
    @version
  end

  def dir_name
    @dir_name
  end

  def ruby_version
    env = { "PATH"     => "#{bundler_path}/bin:#{ENV['PATH']}",
            "RUBYLIB"  => File.join(bundler_path, "gems", dir_name, "lib"),
            "GEM_PATH" => "#{bundler_path}:#{ENV["GEM_PATH"]}",
            "BUNDLE_DISABLE_VERSION_CHECK" => "true"
          }
    command = "bundle platform --ruby"

    # Silently check for ruby version
    output  = run_stdout(command, user_env: true, env: env).strip.lines.last

    # If there's a gem in the Gemfile (i.e. syntax error) emit error
    raise GemfileParseError.new(run("bundle check", user_env: true, env: env)) unless $?.success?

    ruby_version = self.class.platform_to_version(output)
    if ruby_version.nil? || ruby_version.empty?
      warn(<<~WARNING, inline: true)
        No ruby version specified in the Gemfile.lock

        We could not determine the version of Ruby from your Gemfile.lock.

          $ bundle platform --ruby
          #{output}

          $ bundle -v
          #{run("bundle -v", user_env: true, env: env)}

        Ensure the above command outputs the version of Ruby you expect. If you have a ruby version specified in your Gemfile, you can update the Gemfile.lock by running the following command:

          $ bundle update --ruby

        Make sure you commit the results to git before attempting to deploy again:

          $ git add Gemfile.lock
          $ git commit -m "update ruby version"
      WARNING
    end
    ruby_version
  end

  def self.platform_to_version(bundle_platform_output)
    if bundle_platform_output.match(/No ruby version specified/)
      ""
    else
      bundle_platform_output.strip.sub('(', '').sub(')', '').sub(/(p-?\d+)/, ' \1').split.join('-')
    end
  end

  def lockfile_parser
    @lockfile_parser ||= parse_gemfile_lock
  end

  def bundler_version_escape_valve!
    topic("Removing BUNDLED WITH version in the Gemfile.lock")
    contents = File.read(@gemfile_lock_path, mode: "rt")
    File.open(@gemfile_lock_path, "w") do |f|
      f.write contents.sub(/^BUNDLED WITH$(\r?\n)   (?<major>\d+)\.\d+\.\d+/m, '')
    end
  end

  private
  def fetch_bundler
    return true if Dir.exist?(bundler_path)

    topic("Installing bundler #{@version}")
    bundler_version_escape_valve!

    # Install directory structure (as of Bundler 2.1.4):
    # - cache
    # - bin
    # - gems
    # - specifications
    # - build_info
    # - extensions
    # - doc
    FileUtils.mkdir_p(bundler_path)
    Dir.chdir(bundler_path) do
      @fetcher.fetch_untar(@bundler_tar)
    end
    Dir["bin/*"].each {|path| `chmod 755 #{path}` }
  end

  def parse_gemfile_lock
    gemfile_contents = File.read(@gemfile_lock_path)
    Bundler::LockfileParser.new(gemfile_contents)
  end
end
