require 'json'

class LanguagePack::Helpers::Nodebin
  URL = "https://nodebin.herokai.com/v1/"

  def self.query(q)
    response = Net::HTTP.get_response(URI("#{URL}/#{q}"))
    if response.code == '200'
      JSON.parse(response.body)
    end
  end

  def self.hardcoded_node_lts
    version = "10.14.1"
    {
      "number" => version,
      "url"    => "https://s3.amazonaws.com/heroku-nodebin/node/release/linux-x64/node-v#{version}-linux-x64.tar.gz"
    }
  end

  def self.hardcoded_yarn
    version = "1.12.3"
    {
      "number" => version,
      "url"    => "https://s3.amazonaws.com/heroku-nodebin/yarn/release/yarn-v#{version}.tar.gz"
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
