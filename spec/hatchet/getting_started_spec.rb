require_relative '../spec_helper'

describe "Heroku ruby getting started" do
  it "works on Heroku-24" do
    Hatchet::Runner.new("ruby-getting-started", stack: "heroku-24").deploy do |app|
      expect(app.output).to_not include("Purging Cache")
      # Assert sprockets build cache not present on runtime
      expect(app.run("ls tmp/cache/assets")).to_not match("sprockets")

      # Re-deploy with cache
      run!("git commit --allow-empty -m empty")
      app.push!

      # Assert no warnings from `cp`
      # https://github.com/heroku/heroku-buildpack-ruby/pull/1586/files#r2064284286
      expect(app.output).to_not include("cp --help")
      expect(app.run("which ruby").strip).to eq("/app/bin/ruby")

      environment_variables = app.run("env")
      expect(environment_variables).to match("PUMA_PERSISTENT_TIMEOUT")

      profile_d = app.run("cat .profile.d/ruby.sh")
      expect(profile_d).to match("PUMA_PERSISTENT_TIMEOUT")
    end
  end

  it "works on Heroku-22" do
    Hatchet::Runner.new("ruby-getting-started", stack: "heroku-22").deploy do |app|
      # Re-deploy with cache
      run!("git commit --allow-empty -m empty")
      app.push!

      # Assert no warnings from `cp`
      # https://github.com/heroku/heroku-buildpack-ruby/pull/1586/files#r2064284286
      expect(app.output).to_not include("cp --help")
      expect(app.run("which ruby").strip).to eq("/app/bin/ruby")
    end
  end
end
