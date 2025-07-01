require 'spec_helper'

describe "Bundler" do
  it "can be configured with BUNDLE_WITHOUT env var with spaces in it" do
    Hatchet::Runner.new("default_ruby", config: {"BUNDLE_WITHOUT" => "foo bar baz"}).tap do |app|
      app.deploy do
        expect(app.output).to match("BUNDLE_WITHOUT='foo:bar:baz'")
        expect(app.output).to match("Your BUNDLE_WITHOUT contains a space")
      end
    end
  end
end
