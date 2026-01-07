# frozen_string_literal: true

require "json"

# This class is responsible for installing and maintaining a
# reference to bundler. It contains access to bundler internals
# that are used to introspect a project such as detecting presence
# of gems and their versions.
#
# Example:
#
#   bundler = LanguagePack::Helpers::BundlerWrapper.new(bundler_path: "vendor/bundle/ruby/3.2.0", bundler_version: "2.5.7")
#   bundler.install
#   bundler.version                 => "2.5.23"
#   bundler.dir_name                => "bundler-2.5.23"
#   bundler.has_gem?("railties")    => true
#   bundler.gem_version("railties") => "5.2.2"
#   bundler.clean
#
# IMPORTANT: Calling `BundlerWrapper#install` on this class mutates the environment variable
# ENV['BUNDLE_GEMFILE']. If you're calling in a test context (or anything outside)
# of an isolated dyno, you must call `BundlerWrapper#clean`. To reset the environment
# variable:
#
#   bundler = LanguagePack::Helpers::BundlerWrapper.new(bundler_path: "vendor/bundle/ruby/3.2.0", bundler_version: "2.5.7")
#   bundler.install
#   bundler.clean # <========== IMPORTANT =============
#
class LanguagePack::Helpers::BundlerWrapper
  include LanguagePack::ShellHelpers

  # Heroku-22's oldest Ruby version is 3.1
  DEFAULT_VERSION = "2.3.25"

  attr_reader :bundler_path

  def initialize(
      bundler_path:,
      bundler_version:,
      gemfile_path: Pathname.new("./Gemfile"),
      report: HerokuBuildReport::GLOBAL
    )
    @report               = report
    @gemfile_path         = gemfile_path
    @gemfile_lock_path    = Pathname.new("#{@gemfile_path}.lock")

    dot_ruby_version_file = @gemfile_lock_path.join("..").join(".ruby-version")
    @report.capture(
      "ruby.dot_ruby_version" => dot_ruby_version_file.exist? ? dot_ruby_version_file.read&.strip : nil
    )
    @version = bundler_version
    parts = @version.split(".")
    @report.capture(
      "bundler.version_installed" => @version,
      "bundler.major" => parts&.shift,
      "bundler.minor" => parts&.shift,
      "bundler.patch" => parts&.shift
    )
    @dir_name = "bundler-#{@version}"

    @bundler_path = Pathname(bundler_path)
    @orig_bundle_gemfile  = ENV['BUNDLE_GEMFILE']
  end

  def install
    ENV['BUNDLE_GEMFILE'] = @gemfile_path.to_s
    fetch_bundler
    self
  end

  def clean
    ENV['BUNDLE_GEMFILE'] = @orig_bundle_gemfile
  end

  def has_gem?(name)
    specs.key?(name)
  end

  def gem_version(name)
    specs[name]
  end

  def specs
    @specs ||= specs_from_lockfile
  end

  def version
    @version
  end

  def dir_name
    @dir_name
  end

  private def fetch_bundler
    return true if Dir.exist?(bundler_path.join("gems", dir_name))

    topic("Installing bundler #{@version}")

    # Install directory structure (as of Bundler 2.1.4):
    # - cache
    # - bin
    # - gems
    # - specifications
    # - build_info
    # - extensions
    # - doc
    FileUtils.mkdir_p(bundler_path)
    run!("GEM_HOME=#{bundler_path} gem install bundler --version #{@version} --no-document --env-shebang")
  end

  # Runs a Ruby subprocess to parse the Gemfile.lock and return specs as a hash.
  private def specs_from_lockfile
    LanguagePack::Helpers::LockfileShellParser.call(lockfile_path: @gemfile_lock_path)
  end

  def self.resolve_bundler_version(gemfile_lock:, warn_io: )
    version = gemfile_lock.bundler.version
    if version
      version
    else
      warn_io.warn(<<~WARNING)
        Using default bundler version `#{DEFAULT_VERSION}`

        The Ruby buildpack uses the `BUNDLED WITH` value in your `Gemfile.lock` to determine the version
        of bundler to install. Your `Gemfile.lock` does not contain this section, so a default version
        of bundler will be installed instead.

        Heroku recommends that you have both a `RUBY VERSION` and `BUNDLED WITH` version listed in your `Gemfile.lock`.
        You can add it to your project by running:

        ```
        $ bundle update --bundler
        ```

        Commit the results to git before redeploying:

        ```
        $ git add Gemfile.lock
        $ git commit -m "Add BUNDLED WITH version"
        ```
      WARNING

      DEFAULT_VERSION
    end
  end
end
