require_relative 'spec_helper'

describe "bundle jobs" do
  it "defaults to 4 jobs" do
    Hatchet::Runner.new("default_ruby").deploy do |app|
      expect(app.output).to match("-j4")
    end
  end

  it "allows configuring the number of jobs" do
    app = Hatchet::Runner.new("default_ruby")
    app.setup!
    app.set_config("BUNDLE_JOBS" => "2")

    app.deploy do |app|
      expect(app.output).to match("-j2")
    end
  end
end
