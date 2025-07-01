require_relative '../spec_helper'

describe "Rails 2.3.x" do
  it "should deploy" do
    skip("Need RAILS_LTS_CREDS env var set") unless ENV["RAILS_LTS_CREDS"]

    Hatchet::Runner.new('rails_lts_23_default_ruby', config: rails_lts_config, stack: rails_lts_stack).tap do |app|
      app.deploy do
        # assert deploy is successful
      end
    end
  end
end
