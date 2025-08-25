#!/usr/bin/env ruby

# This script will detect which test script or framework an app is likely to be
# using and run the appropriate command. It is expected that `ruby_test-compile`
# will be run before this file, this installs a version of Ruby and any dependencies
# a customer's app needs.
$stdout.sync = true

$:.unshift File.expand_path("../../../lib", __FILE__)
require "language_pack"
require "language_pack/shell_helpers"
require "language_pack/test"
require "language_pack/ruby"

include LanguagePack::ShellHelpers

def execute_test(command)
  topic("Running test: #{command}")
  execute_command(command)
  exit $?.exitstatus
end

def execute_command(command)
  # Normally the `pipe` command will indent output so that it
  # matches the build output, however in a test TAP depends on
  # having no whitespace before output. To avoid adding whitespace
  # for the original Kernel.puts to be used by passing in the
  # Kernel object.
  pipe(command, :user_env => true, :output_object => Kernel)
end

def user_env_hash
  LanguagePack::ShellHelpers.user_env_hash
end

# $ bin/test BUILD_DIR ENV_DIR ARTIFACT_DIR
build_dir, env_dir, _ = ARGV
LanguagePack::ShellHelpers.initialize_env(env_dir)
Dir.chdir(build_dir)

# The `ruby_test-compile` program installs a version of Ruby for the
# user's application. It needs the propper `PATH`, where ever Ruby is installed
# otherwise we end up using the buildpack's version of Ruby
#
# This is needed here because LanguagePack::Ruby.slug_vendor_base shells out to the user's ruby binary
user_env_hash["PATH"] = "#{build_dir}/bin:#{ENV["PATH"]}"

bundler = LanguagePack::Helpers::BundlerWrapper.new(
  gemfile_path: "#{build_dir}/Gemfile",
  bundler_path: LanguagePack::Ruby.slug_vendor_base # This was previously installed by bin/support/ruby_test-compile
)

# - Add bundler's bin directory to the PATH
# - Always make sure `$HOME/bin` is first on the path
user_env_hash["PATH"] = "#{build_dir}/bin:#{bundler.bundler_path}/bin:#{user_env_hash["PATH"]}"
user_env_hash["GEM_PATH"] = LanguagePack::Ruby.slug_vendor_base

# - Sets BUNDLE_GEMFILE
# - Loads bundler's internal Gemfile.lock parser so we can use `bundler.has_gem?`
bundler.install

execute_test(
  if bundler.has_gem?("rspec-core")
    if File.exist?("bin/rspec")
      "bin/rspec"
    else
      "bundle exec rspec"
    end
  elsif File.exist?("bin/rails") && bundler.has_gem?("railties") && bundler.gem_version("railties") >= Gem::Version.new("5.x")
    "bin/rails test"
  elsif File.exist?("bin/rake")
    "bin/rake test"
  else
    "rake test"
  end
)

