require 'spec_helper'

describe "Multibuildpack" do
  it "works with node" do
    Hatchet::Runner.new("node_multi", buildpack_url: "https://github.com/heroku/heroku-buildpack-multi.git").deploy do |app|
      expect(app.output).to match("Node Version in Ruby buildpack is: v4.1.2")
      expect(app.run("node -v")).to match("v4.1.2")
    end
  end

  it "node is installed by default without multi buildpack" do
    default_node_version = LanguagePack::Helpers::NodeInstaller.new.version
    Hatchet::Runner.new("node_multi").deploy do |app|
      expect(app.output).to match("Node Version in Ruby buildpack is: v#{default_node_version}")
      expect(app.run("node -v")).to match(default_node_version)
    end
  end

  it "doesn't install node without exec JS" do
    Hatchet::Runner.new("default_ruby").deploy do |app|
      expect(app.run("node -v")).to match("node: command not found")
    end
  end
end

