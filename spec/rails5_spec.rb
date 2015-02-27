require_relative 'spec_helper'

describe "Rails 5.x" do

  it "works" do
    Hatchet::Runner.new("rails5").deploy do |app, heroku|
      expect(app.run("rails -v")).to match("")
    end
  end
end
