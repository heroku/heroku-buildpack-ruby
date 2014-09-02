require 'bundler/setup'
require 'machete'
require 'machete/matchers'
require 'rspec/retry'

`mkdir -p log`
Machete.logger = Machete::Logger.new("log/integration.log")
