require 'spec_helper'

describe "Upgrading ruby apps" do
  it "upgrades from 2.0.0 to 2.1.0" do
    Hatchet::Runner.new("mri_200").deploy do |app|
      expect(app.run("ruby -v")).to match("2.0.0")

      `echo "" > Gemfile; echo "" > Gemfile.lock`
      puts `env BUNDLE_GEMFILE=./Gemfile bundle install`.inspect
      `echo "ruby '2.1.4'" > Gemfile`
      `git add -A; git commit -m update-ruby`
      app.push!
      expect(app.output).to match("2.1.4")
      expect(app.run("ruby -v")).to match("2.1.4")
      expect(app.output).to match("Ruby version change detected")
    end
  end
end
