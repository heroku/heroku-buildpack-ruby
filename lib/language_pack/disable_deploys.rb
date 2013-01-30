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
    error "Ruby deploys have been temporarily disabled. We will have more information available shortly, including a workaround."
  end
end

