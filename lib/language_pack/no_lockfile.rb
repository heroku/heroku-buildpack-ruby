require "language_pack"
require "language_pack/ruby"

class LanguagePack::NoLockfile < LanguagePack::Ruby
  def self.use?
    !File.exist?("Gemfile.lock") &&
    !File.exist?("gems.locked")
  end

  def name
    "Ruby/NoLockfile"
  end

  def compile
    error "'Gemfile.lock' or 'gems.locked' required. Please check it in."
  end
end
