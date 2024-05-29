require 'json'

class LanguagePack::Helpers::Nodebin
  NODE_VERSION = "20.9.0"
  YARN_VERSION = "1.22.19"
  CUSTOM_HEROKU_NODEBIN_HOST = ENV["CUSTOM_HEROKU_NODEBIN_HOST"] || "https://heroku-nodebin.s3.us-east-1.amazonaws.com"
  
  def self.hardcoded_node_lts
    {
      "number" => NODE_VERSION,
      "url"    => "#{CUSTOM_HEROKU_NODEBIN_HOST}/node/release/linux-x64/node-v#{NODE_VERSION}-linux-x64.tar.gz"
    }
  end

  def self.hardcoded_yarn
    {
      "number" => YARN_VERSION,
      "url"    => "#{CUSTOM_HEROKU_NODEBIN_HOST}/yarn/release/yarn-v#{YARN_VERSION}.tar.gz"
    }
  end

  def self.node_lts
    hardcoded_node_lts
  end

  def self.yarn
    hardcoded_yarn
  end
end
