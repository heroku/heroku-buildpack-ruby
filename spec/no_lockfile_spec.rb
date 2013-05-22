require 'spec_helper'

describe "No Lockfile" do
  it "should not deploy" do
    Hatchet::AnvilApp.new("no_lockfile").deploy do |app, heroku, output|
      expect(app).not_to be_deployed
      expect(output).to include("ERROR: Gemfile.lock required")
    end
  end
end
