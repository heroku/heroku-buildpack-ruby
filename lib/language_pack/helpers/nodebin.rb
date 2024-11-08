require 'json'

class LanguagePack::Helpers::Nodebin
  NODE_VERSION = "22.11.0"
  YARN_VERSION = "1.22.22"

  def self.hardcoded_node_lts(arch: )
    arch = "x64" if arch == "amd64"
    {
      "number" => NODE_VERSION,
      "url"    => "https://nodejs.org/download/release/v#{NODE_VERSION}/node-v#{NODE_VERSION}-linux-#{arch}.tar.gz",
    }
  end

  def self.hardcoded_yarn
    {
      "number" => YARN_VERSION,
      "url"    => "https://heroku-nodebin.s3.us-east-1.amazonaws.com/yarn/release/yarn-v#{YARN_VERSION}.tar.gz"
    }
  end

  def self.node_lts(arch: )
    hardcoded_node_lts(arch: arch)
  end

  def self.yarn
    hardcoded_yarn
  end
end
