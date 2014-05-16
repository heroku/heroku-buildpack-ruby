require 'bundler/setup'
require 'machete'

`mkdir -p log`
Machete.logger = Machete::Logger.new("log/integration.log")

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
end