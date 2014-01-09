require 'spec_helper'

describe "Default Cache" do
  it "gets loaded successfully on default Ruby" do
    Hatchet::Runner.new("default_ruby").deploy do |app|
      expect(app.output).to match("loading default bundler cache")
    end
  end

  it "gets loaded correctly on Ruby 2.1.0" do
    Hatchet::Runner.new("mri_210").deploy do |app|
      expect(app.output).to match("loading default bundler cache")
    end
  end
end
