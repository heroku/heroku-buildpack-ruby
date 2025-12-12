#!/usr/bin/env ruby

# This script installs an app's Ruby version and dependencies. It's
# essentially the same thing as `ruby_compile` (which is called by bin/compile)
# except that some behavior is cusomtized by the inclusion of the
# `language_pack/test` file. One difference is dependencies
# the `bin/compile` installs dependencies via bundler and excludes `development:test`
# gems, however we need `test` gems to run tests, so instead only `development`
# is excluded.
#
# It also sets up the database (if one is present) and populates the database
# with the appropriate schema.
$stdout.sync = true

$:.unshift File.expand_path("../../../lib", __FILE__)
require "language_pack"
require "language_pack/shell_helpers"
require "language_pack/test"
include LanguagePack::ShellHelpers

begin
  app_path = Pathname(ARGV[0])
  cache_path = Pathname(ARGV[1])
  gemfile_lock = LanguagePack.gemfile_lock(app_path: app_path)
  Dir.chdir(app_path)

  LanguagePack::ShellHelpers.initialize_env(ARGV[2])
  LanguagePack.call(
    app_path: app_path,
    cache_path: cache_path,
    gemfile_lock: gemfile_lock,
    bundle_default_without: "development",
    environment_name: "test",
  )
rescue Exception => e
  LanguagePack::ShellHelpers.display_error_and_exit(e)
end
