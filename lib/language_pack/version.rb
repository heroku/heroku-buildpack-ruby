require "language_pack/base"

module LanguagePack
  class LanguagePack::Base
    VERSION_FILE = File.expand_path('../../../VERSION', __FILE__)
    CF_BUILDPACK_VERSION = File.readlines(VERSION_FILE).first.chomp
    BUILDPACK_VERSION = "v197"
  end
end
