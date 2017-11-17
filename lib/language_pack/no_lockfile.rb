require "language_pack"
require "language_pack/base"

class LanguagePack::NoLockfile < LanguagePack::Base
  def self.use?
    ["gems.locked", "Gemfile.lock"].none? { |lockfile| !File.exists?(lockfile) }
  end

  def name
    "Ruby/NoLockfile"
  end

  def compile
    error "Gemfile.lock or gems.locked required. Please check it in."
  end
end
