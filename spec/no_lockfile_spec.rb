require 'spec_helper'

describe "No Lockfile" do
  it "should not deploy" do
    Hatchet::AnvilApp.new("no_lockfile", allow_failure: true).deploy do |app, heroku, output|
      expect(app).not_to be_deployed
      expect(output).to include("Gemfile.lock required")
    end
  end
end
