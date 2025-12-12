#!/usr/bin/env ruby

# This script compiles an application so it can run on Heroku.
# It will install the application's specified version of Ruby, it's dependencies
# and certain framework specific requirements (such as calling `rake assets:precompile`
# for rails apps). You can see all features described in the devcenter
# https://devcenter.heroku.com/articles/ruby-support
$stdout.sync = true

$:.unshift File.expand_path("../../../lib", __FILE__)
require "language_pack"
require "language_pack/shell_helpers"
HerokuBuildReport.set_global(
  path: Pathname(ENV.fetch("HEROKU_RUBY_BUILD_REPORT_FILE"))
)

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
    bundle_default_without: "development:test",
  )
rescue Exception => e
  LanguagePack::ShellHelpers.display_error_and_exit(e)
end
