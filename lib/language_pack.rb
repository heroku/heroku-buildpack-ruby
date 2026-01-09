require "pathname"
require 'benchmark'

require 'language_pack/shell_helpers'
require "language_pack/helpers/gemfile_lock"

# General Language Pack module
module LanguagePack
  module Helpers
  end

  def self.gemfile_lock(app_path: )
    path = app_path.join("Gemfile.lock")
    if path.exist?
      LanguagePack::Helpers::GemfileLock.new(
        contents: path.read
      )
    else
      raise BuildpackError.new("Gemfile.lock required. Please check it in.")
    end
  end

  def self.call(app_path:, cache_path:, gemfile_lock:, bundle_default_without:, environment_name: "production")
    arch = LanguagePack::Base.get_arch
    stack = ENV.fetch("STACK")
    cache = LanguagePack::Cache.new(cache_path)
    warn_io = LanguagePack::ShellHelpers::WarnIO.new
    user_env_hash = LanguagePack::ShellHelpers.user_env_hash
    bundler_cache = LanguagePack::BundlerCache.new(cache, stack)
    bundler_version = LanguagePack::Helpers::BundlerWrapper.resolve_bundler_version(
      warn_io: warn_io,
      gemfile_lock: gemfile_lock,
    )

    metadata = LanguagePack::Metadata.new(cache_path: cache_path)
    new_app = metadata.empty?

    ruby_version = Ruby.get_ruby_version(
      report: HerokuBuildReport::GLOBAL,
      metadata: metadata,
      gemfile_lock: gemfile_lock
    )

    Ruby.remove_vendor_bundle(app_path: app_path)
    Ruby.warn_bundler_upgrade(metadata: metadata, bundler_version: bundler_version)
    Ruby.warn_bad_binstubs(app_path: app_path, warn_object: warn_io)
    Ruby.install_ruby(
      app_path: app_path,
      ruby_version: ruby_version,
      stack: stack,
      arch: arch,
      metadata: metadata,
      io: warn_io
    )

    bundler = Helpers::BundlerWrapper.new(bundler_path: ruby_version.bundler_directory, bundler_version: bundler_version).install
    default_config_vars = Ruby.default_config_vars(metadata: metadata, ruby_version: ruby_version, bundler: bundler, environment_name: environment_name)
    Ruby.setup_language_pack_environment(
      app_path: app_path.expand_path,
      ruby_version: ruby_version,
      user_env_hash: user_env_hash,
      bundle_default_without: bundle_default_without,
      default_config_vars: default_config_vars
    )
    Ruby.load_bundler_cache(
      ruby_version: ruby_version,
      new_app: new_app,
      cache: cache,
      metadata: metadata,
      stack: stack,
      bundler_cache: bundler_cache,
      bundler_version: bundler_version,
      bundler: bundler,
      io: warn_io
    )

    bundler_output = String.new # buffer
    Ruby.build_bundler(
      ruby_version: ruby_version,
      app_path: app_path,
      io: warn_io,
      bundler_cache: bundler_cache,
      bundler_version: bundler_version,
      bundler_output: bundler_output,
    )

    gems = Ruby.bundle_list(
        io: warn_io,
        stream_to_user: !bundler_output.match?(/Installing|Fetching|Using/)
    )

    if pack = LanguagePack.detect(
        arch: arch,
        new_app: new_app,
        warn_io: warn_io,
        bundler: bundler,
        app_path: app_path,
        cache_path: cache_path,
        ruby_version: ruby_version,
        gemfile_lock: gemfile_lock,
        environment_name: environment_name
      )
      pack.topic("Compiling #{pack.name}")
      pack.compile
    end
  end

  # detects which language pack to use
  def self.detect(arch:, app_path:, cache_path:, environment_name:, gemfile_lock:, new_app:, ruby_version:, warn_io:, bundler:)
    pack_klass = [ Rails8, Rails7, Rails6, Rails5, Rails4, Rails3, Rails2, Rack, Ruby ].detect do |klass|
      klass.use?(bundler: bundler)
    end

    if pack_klass
      pack_klass.new(
        arch: arch,
        bundler: bundler,
        new_app: new_app,
        warn_io: warn_io,
        app_path: app_path,
        cache_path: cache_path,
        environment_name: environment_name,
        gemfile_lock: gemfile_lock,
        ruby_version: ruby_version,
      )
    else
      nil
    end
  end
end

$:.unshift File.expand_path("../../vendor", __FILE__)
$:.unshift File.expand_path("..", __FILE__)

require 'heroku_build_report'

require "language_pack/helpers/plugin_installer"
require "language_pack/helpers/stale_file_cleaner"
require "language_pack/helpers/bundle_list"
require "language_pack/helpers/rake_runner"
require "language_pack/helpers/rails_runner"
require "language_pack/helpers/puma_warn_error"
require "language_pack/helpers/bundler_wrapper"
require "language_pack/helpers/lockfile_shell_parser"
require "language_pack/helpers/default_env_vars"
require "language_pack/helpers/outdated_ruby_version"
require "language_pack/helpers/download_presence"
require "language_pack/installers/heroku_ruby_installer"

require "language_pack/ruby"
require "language_pack/rack"
require "language_pack/rails2"
require "language_pack/rails3"
require "language_pack/rails4"
require "language_pack/rails5"
require "language_pack/rails6"
require "language_pack/rails7"
require "language_pack/rails8"
