require 'spec_helper'

describe "JvmInstaller" do
  it "JVM is installed by jvm-common only" do
    buildpacks = ["https://github.com/heroku/heroku-buildpack-jvm-common",
                  Hatchet::App.default_buildpack] # default is heroku-ruby-buildpack here
    app = Hatchet::Runner.new("ruby_193_jruby_17161", stack: 'cedar-14', buildpacks: buildpacks)
    app.setup!

    app.deploy do |app|
      expect(app.output).to match("Using pre-installed JDK")
      expect(app.run("java -version")).to match("1.8.0")
      sleep 3
      expect(app.run("ls .jdk/jre/lib/ext")).to match("pgconfig.jar")
    end
  end
end
