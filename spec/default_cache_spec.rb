require 'spec_helper'

describe "Default Cache" do
  it "gets loaded successfully" do
    pending("needs dep-tracker work")
    Hatchet::Runner.new("default_ruby").deploy do |app|
      expect(app.output).to match("loading default bundler cache")
    end
  end
end

