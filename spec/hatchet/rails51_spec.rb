require "spec_helper"

describe "Rails 5.1" do
  it "works with webpacker + yarn (js friends)" do
    Hatchet::Runner.new("rails51_webpacker").deploy do |app, heroku|
      expect(app.output).to include("Installing yarn")
      expect(app.output).to include("yarn install")
      expect(app.run("rails -v")).to match("")
    end
  end
end
