require "language_pack"
require "language_pack/ruby"

class LanguagePack::NoLockfile < LanguagePack::Ruby
  def self.use?
    !File.exists?("Gemfile.lock")
  end

  def name
    "Ruby/NoLockfile"
  end

  def compile
    error "Gemfile.lock required. Please check it in."
  end
end
