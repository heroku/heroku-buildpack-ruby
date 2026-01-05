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

# $ bin/test app_path ENV_DIR ARTIFACT_DIR
app_path, env_dir, _ = ARGV.map { |arg| Pathname(arg).expand_path }
LanguagePack::ShellHelpers.initialize_env(env_dir)
Dir.chdir(app_path)

gems_list = LanguagePack::Helpers::BundleList::HumanCommand.new(
  stream_to_user: false,
).call

execute_test(
  if gems_list.has_gem?("rspec-core")
    if File.exist?("bin/rspec")
      "bin/rspec"
    else
      "bundle exec rspec"
    end
  elsif File.exist?("bin/rails") && gems_list.has_gem?("railties") && gems_list.gem_version("railties") >= Gem::Version.new("5.x")
    "bin/rails test"
  elsif File.exist?("bin/rake")
    "bin/rake test"
  else
    "rake test"
  end
)

