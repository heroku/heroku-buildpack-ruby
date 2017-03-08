require 'json'

class LanguagePack::Nodebin
  URL = "https://nodebin.herokai.com/v1/"

  def self.query(q)
    response = Net::HTTP.get_response(URI("#{URL}/#{q}"))
    if response.code == '200'
      JSON.parse(response.body)
    end
  end

  def self.node(q)
    query("node/linux-x64/#{q}")
  end

  def self.node_lts
    node("latest?range=6.x")
  end

  def self.yarn(q)
    query("yarn/linux-x64/#{q}")
  end
end
