require 'rspec/core'
require 'hatchet'
require 'fileutils'
require 'hatchet'

ENV['RACK_ENV'] = 'test'

RSpec.configure do |config|
  config.filter_run :focused => true
  config.run_all_when_everything_filtered = true
  config.alias_example_to :fit, :focused => true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.mock_with :none
end

def git_repo
  "https://github.com/heroku/heroku-buildpack-ruby.git"
end

def add_database(app, heroku)
  heroku.post_addon(app.name, 'heroku-postgresql:dev')
  _, value = heroku.get_config_vars(app.name).body.detect {|key, value| key.match(/HEROKU_POSTGRESQL_[A-Z]+_URL/) }
  heroku.put_config_vars(app.name, 'DATABASE_URL' => value)
end

def successful_body(app, options = {})
  retry_limit = options[:retry_limit] || 50
  Excon.get("http://#{app.name}.herokuapp.com", :idempotent => true, :expects => 200, :retry_limit => retry_limit).body
end
