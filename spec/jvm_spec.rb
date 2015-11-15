require 'spec_helper'

describe "JvmInstaller" do
  it "JVM is installed by jvm-common only" do
    app = Hatchet::Runner.new("ruby_193_jruby_17161")
    app.setup!
    bp = app.heroku.get_config_vars(app.name).body["BUILDPACK_URL"]
    app.heroku.delete_config_var(app.name, "BUILDPACK_URL")
    app.heroku.put_buildpacks(app.name, ["https://github.com/heroku/heroku-buildpack-jvm-common", bp])

    app.deploy do |app|
      expect(app.output).to match("Using pre-installed JDK")
      expect(app.run("java -version")).to match("1.8.0")
    end
  end
end
