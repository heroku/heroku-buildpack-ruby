require_relative 'spec_helper'

describe "Rails 4.2.x" do
  it "call the `finish:deploy` rake task if defined" do
    Hatchet::Runner.new("rails42_finish_deploy").deploy do |app, heroku|
      expect(app.output).to include("Hello from a custom rake task")
    end
  end
end
