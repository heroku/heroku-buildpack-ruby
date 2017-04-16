require 'spec_helper'

describe "CI" do
  it "Does not cause the double ruby rainbow bug" do
    Hatchet::Runner.new("heroku-ci-json-example").run_ci do |test_run|
      expect(test_run.status).to eq(:succeeded)
    end
  end
end
