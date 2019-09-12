require 'json'

class LanguagePack::Helpers::Nodebin
  def self.hardcoded_node_lts
    version = "10.15.3"
    {
      "number" => version,
      "url"    => "https://s3.amazonaws.com/heroku-nodebin/node/release/linux-x64/node-v#{version}-linux-x64.tar.gz"
    }
  end

  def self.hardcoded_yarn
    version = "1.16.0"
    {
      "number" => version,
      "url"    => "https://s3.amazonaws.com/heroku-nodebin/yarn/release/yarn-v#{version}.tar.gz"
    }
  end

  def self.node_lts
    hardcoded_node_lts
  end

  def self.yarn
    hardcoded_yarn
  end
end
