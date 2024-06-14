require_relative '../spec_helper'

describe "Heroku ruby getting started" do
  it "clears runtime cache" do
    Hatchet::Runner.new("ruby-getting-started").deploy do |app|
      expect(app.run("ls tmp/cache/assets")).to_not match("sprockets")
    end
  end

  it "works on Heroku-24" do
    Hatchet::Runner.new("ruby-getting-started", stack: "heroku-24").deploy do |app|
      expect(app.run("which ruby").strip).to eq("/app/bin/ruby")
    end
  end
end
