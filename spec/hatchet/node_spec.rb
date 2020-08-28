require 'spec_helper'

describe "Node and Yarn" do
  it "works without the node buildpack" do
    buildpacks = [
      :default,
      "https://github.com/sharpstone/force_absolute_paths_buildpack"
    ]
    config = {FORCE_ABSOLUTE_PATHS_BUILDPACK_IGNORE_PATHS: "BUNDLE_PATH"}

    Hatchet::Runner.new("minimal_webpacker", buildpacks: buildpacks, config: config).deploy do |app, heroku|
      # https://rubular.com/r/4bkL8fYFTQwt0Q
      expect(app.output).to match(/vendor\/yarn-v\d+\.\d+\.\d+\/bin\/yarn is the yarn directory/)
      expect(app.output).to_not include(".heroku/yarn/bin/yarn is the yarn directory")

      expect(app.output).to include("bin/node is the node directory")
      expect(app.output).to_not include(".heroku/node/bin/node is the node directory")

      expect(app.run("which node")).to match("/app/bin/node")     # We put node in bin/node
      expect(app.run("which yarn")).to match("/app/vendor/yarn-") # We put yarn in /app/vendor/yarn-
    end
  end

  it "works with the node buildpack" do
    buildpacks = [
      "heroku/nodejs",
      :default,
      "https://github.com/sharpstone/force_absolute_paths_buildpack"
    ]
    config = {FORCE_ABSOLUTE_PATHS_BUILDPACK_IGNORE_PATHS: "BUNDLE_PATH"}

    Hatchet::Runner.new("minimal_webpacker", buildpacks: buildpacks, config: config).deploy do |app, heroku|
      expect(app.output).to include("yarn install")
      expect(app.output).to include(".heroku/yarn/bin/yarn is the yarn directory")
      expect(app.output).to include(".heroku/node/bin/node is the node directory")

      expect(app.run("which node")).to match("/app/.heroku/node/bin")
      expect(app.run("which yarn")).to match("/app/.heroku/yarn/bin")
    end
  end
end

