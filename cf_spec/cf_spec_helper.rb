require 'bundler/setup'
require 'machete'

`mkdir -p log`
Machete.logger = Machete::Logger.new("log/integration.log")

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.before(:suite) do
    Machete::BuildpackUploader.new(:ruby)
  end
end
