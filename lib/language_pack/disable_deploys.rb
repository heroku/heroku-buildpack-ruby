require "language_pack"
require "language_pack/base"

class LanguagePack::DisableDeploys < LanguagePack::Base
  def self.use?
    File.exist?("Gemfile")
  end

  def name
    "Ruby/DisableDeploys"
  end

  def compile
    error "Ruby deploys have been temporarily disabled due to a Rubygems.org security breach.\nPlease see https://status.heroku.com/incidents/489 for more info and a workaround if you need to deploy."
  end
end

