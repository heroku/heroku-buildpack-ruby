require 'spec_helper'
require 'language_pack'

ENV["BUILDPACK_CACHE"] = "/var/vcap/packages/buildpack_cache"

RSpec.configure do |config|
  config.mock_with :rspec
end