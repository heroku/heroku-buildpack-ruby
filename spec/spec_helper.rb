require 'rspec/core'
require 'hatchet'
require 'fileutils'
require 'stringio'
require 'hatchet'
require 'rspec/retry'
require 'language_pack'
require 'language_pack/shell_helpers'

ENV["HATCHET_BUILDPACK_BASE"] = "https://github.com/heroku/heroku-buildpack-ruby"

ENV['RACK_ENV'] = 'test'

DEFAULT_STACK = 'heroku-18'

RSpec.configure do |config|
  config.filter_run focused: true unless ENV['IS_RUNNING_ON_CI']
  config.run_all_when_everything_filtered = true
  config.alias_example_to :fit, focused: true
  config.full_backtrace      = true
  config.verbose_retry       = true # show retry status in spec process
  config.default_retry_count = 2 if ENV['IS_RUNNING_ON_CI'] # retry all tests that fail again

  config.expect_with :rspec do |c|
    c.max_formatted_output_length = Float::INFINITY
    c.syntax = :expect
  end
  config.mock_with :nothing
  config.include LanguagePack::ShellHelpers
end

def successful_body(app, options = {})
  retry_limit = options[:retry_limit] || 50
  url = "http://#{app.name}.herokuapp.com"
  Excon.get(url, :idempotent => true, :expects => 200, :retry_limit => retry_limit).body
end

def create_file_with_size_in(size, dir)
  name = File.join(dir, SecureRandom.hex(16))
  File.open(name, 'w') {|f| f.print([ 1 ].pack("C") * size) }
  Pathname.new name
end

if ENV['TRAVIS']
  # Don't execute tests against "merge" commits
  exit 0 if ENV['TRAVIS_PULL_REQUEST'] != 'false' && ENV['TRAVIS_BRANCH'] == 'master'
end

def buildpack_path
  File.expand_path(File.join("../.."), __FILE__)
end

def fixture_path(path)
  Pathname.new(__FILE__).join("../fixtures").expand_path.join(path)
end

def rails_lts_config
  { 'BUNDLE_GEMS__RAILSLTS__COM' => ENV["RAILS_LTS_CREDS"] }
end

def hatchet_path(path = "")
  Pathname.new(__FILE__).join("../../repos").expand_path.join(path)
end

def dyno_status(app, ps_name = "web")
  app
    .api_rate_limit.call
    .dyno
    .list(app.name)
    .detect {|x| x["type"] == ps_name }
end

def wait_for_dyno_boot(app, ps_name = "web", sleep_val = 1)
  while ["starting", "restarting"].include?(dyno_status(app, ps_name)["state"])
    sleep sleep_val
  end
  dyno_status(app, ps_name)
end

def web_boot_status(app)
  wait_for_dyno_boot(app)["state"]
end
