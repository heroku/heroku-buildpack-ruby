require_relative '../spec_helper'

describe "Heroku ruby getting started" do
  it "clears runtime cache" do
    Hatchet::Runner.new("ruby-getting-started").deploy do |app|
      expect(app.run("ls tmp/cache/assets")).to_not match("sprockets")
    end
  end
end
