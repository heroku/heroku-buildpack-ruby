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

  def self.call(app_path:, cache_path:, gemfile_lock: , bundle_default_without: )
    arch = LanguagePack::Base.get_arch
    metadata = LanguagePack::Metadata.new(cache_path: cache_path)
    cache = LanguagePack::Cache.new(cache_path)
    warn_io = LanguagePack::ShellHelpers::WarnIO.new
    new_app = metadata.empty?
    bundler_output = String.new # buffer

    bundler = ::LanguagePack::Ruby.bundler
    ruby_version = ::LanguagePack::Ruby.get_ruby_version(
      report: HerokuBuildReport::GLOBAL,
      metadata: metadata,
      gemfile_lock: gemfile_lock
    )

    ::LanguagePack::Ruby.install_ruby_bundle_install(
      app_path: app_path,
      metadata: metadata,
      bundler_version: bundler.version,
      warn_io: warn_io,
      ruby_version: ruby_version,
      stack: ENV.fetch("STACK"),
      arch: arch,
      user_env_hash: LanguagePack::ShellHelpers.user_env_hash,
      default_config_vars: ::LanguagePack::Ruby.default_config_vars(metadata: metadata, ruby_version: ruby_version, bundler: bundler),
      new_app: new_app,
      cache: cache,
      bundler_cache: LanguagePack::BundlerCache.new(cache, ENV.fetch("STACK")),
      bundle_default_without: bundle_default_without,
      bundler_output: bundler_output,
    )
    gems = ::LanguagePack::Ruby.bundle_list(
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
        gemfile_lock: gemfile_lock
      )
      pack.topic("Compiling #{pack.name}")
      pack.compile
    end
  end

  # detects which language pack to use
  def self.detect(arch:, app_path:, cache_path:, gemfile_lock:, new_app:, ruby_version:, warn_io: , bundler:)
    pack_klass = [ Rails8, Rails7, Rails6, Rails5, Rails4, Rails3, Rails2, Rack, Ruby ].detect do |klass|
      klass.use?(bundler: bundler)
    end

    if pack_klass
      pack_klass.new(
        arch: arch,
        new_app: new_app,
        warn_io: warn_io,
        app_path: app_path,
        cache_path: cache_path,
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
