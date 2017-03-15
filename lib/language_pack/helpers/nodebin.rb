require 'json'

class LanguagePack::Helpers::Nodebin
  URL = "https://nodebin.herokai.com/v1/"

  def self.query(q)
    response = Net::HTTP.get_response(URI("#{URL}/#{q}"))
    if response.code == '200'
      JSON.parse(response.body)
    end
  end

  def self.hardcoded_node_lts(q)
    {
      number: "6.10.0",
      url:    "https://s3.amazonaws.com/heroku-nodejs-bins/node/release/linux-x64/node-v6.10.0-linux-x64.tar.gz"
    }
  end

  def self.hardcoded_yarn(q)
    {
      number: "0.22.0",
      url:    "https://s3.amazonaws.com/heroku-nodejs-bins/yarn/release/yarn-v0.22.0.tar.gz"
    }
  end

  def self.node(q)
    query("node/linux-x64/#{q}")
  end

  def self.node_lts
    hardcoded_node_lts # node("latest?range=6.x")
  end

  def self.yarn(q)
    hardcoded_yarn # query("yarn/linux-x64/#{q}")
  end
end
