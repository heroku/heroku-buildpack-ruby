require 'spec_helper'

describe "Upgrading ruby apps" do
  it "upgrades from 2.0.0 to 2.1.0" do
    Hatchet::Runner.new("mri_200").deploy do |app|
      expect(app.run("ruby -v")).to match("2.0.0")

      `echo "" > Gemfile; rm Gemfile.lock`
      `env BUNDLE_GEMFILE=./Gemfile bundle install`
      `echo "ruby '2.1.0'" > Gemfile`
      `git add . ; git commit -m update-ruby`
      app.push!
      expect(app.output).to match("2.1.0")
      expect(app.run("ruby -v")).to match("2.1.0")
    end
  end
end
