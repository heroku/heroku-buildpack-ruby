require 'json'

class LanguagePack::Helpers::Nodebin
  def self.hardcoded_node_lts
    version = "16.13.1"
    {
      "number" => version,
      "url"    => "https://heroku-nodebin.s3.us-east-1.amazonaws.com/node/release/linux-x64/node-v#{version}-linux-x64.tar.gz"
    }
  end

  def self.hardcoded_yarn
    version = "1.22.17"
    {
      "number" => version,
      "url"    => "https://heroku-nodebin.s3.us-east-1.amazonaws.com/yarn/release/yarn-v#{version}.tar.gz"
    }
  end

  def self.node_lts
    hardcoded_node_lts
  end

  def self.yarn
    hardcoded_yarn
  end
end
