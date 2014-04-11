require 'spec_helper'

describe "Multibuildpack" do
  it "works with node" do
    Hatchet::Runner.new("node_multi", buildpack_url: "https://github.com/ddollar/heroku-buildpack-multi.git").deploy do |app|
      puts app.output
      expect(app.output).to match("Node Version in Ruby buildpack is: v0.10.3")
    end
  end
end

