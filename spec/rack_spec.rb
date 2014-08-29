require_relative 'spec_helper'

describe "Rack" do
  it "should not overwrite already set environment variables" do
    custom_env = "FFFUUUUUUU"
    app = Hatchet::Runner.new("default_ruby")
    app.setup!
    app.set_config("RACK_ENV" => custom_env)
    expect(app.run("env")).to match(custom_env)

    app.deploy do |app|
      expect(app.run("env")).to match(custom_env)
    end
  end
end
