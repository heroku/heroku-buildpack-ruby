require_relative '../spec_helper'

describe "Buildpack internals" do
  it "handles PATH with a newline in it correctly" do
    buildpacks = [
      "https://github.com/sharpstone/export_path_with_newlines_buildpack",
      Hatchet::App.default_buildpack,
      "https://github.com/heroku/null-buildpack"
    ]
    Hatchet::Runner.new("default_ruby", buildpacks: buildpacks).deploy do |app|
      expect(app.output).to_not match("No such file or directory")
    end
  end
end

