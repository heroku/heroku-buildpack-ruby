require "spec_helper"

describe "Rails 5.1" do
  fit "works with webpacker + yarn (js friends)" do
    Hatchet::Runner.new("rails51_webpacker").deploy do |app, heroku|
      puts app.output
      expect(app.run("rails -v")).to match("")
    end
  end
end
