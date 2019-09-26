require 'spec_helper'

describe "Bundler" do
  it "deploys with version 2.x" do
    before_deploy = -> { run!(%Q{printf "\nBUNDLED WITH\n   2.0.1\n" >> Gemfile.lock}) }

    Hatchet::Runner.new("default_ruby", before_deploy: before_deploy).deploy do |app|
      expect(app.output).to match("Installing dependencies using bundler 2.")
    end
  end
end
