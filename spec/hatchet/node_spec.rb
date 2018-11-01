require 'spec_helper'

describe "Node" do
  it "works with node buildpack" do
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

  it "doesn't install node without execjs or webpacker" do
    Hatchet::Runner.new("default_ruby").deploy do |app|
      expect(app.run("node -v")).to match("node: command not found")
    end
  end

  it "installs node when webpacker is detected but no execjs" do
    Hatchet::Runner.new("webpacker_no_execjs").deploy do |app|
      expect(app.output).to match("Installing node-v")
    end
  end
end

