DEPENDENCIES_PATH = File.expand_path("../../dependencies", File.expand_path($0))
DEPENDENCIES_TRANSLATION_REGEX = /[:\/]/
DEPENDENCIES_TRANSLATION_DELIMITER = '_'

require 'cloud_foundry/language_pack/fetcher'
require 'cloud_foundry/language_pack/ruby'
require 'cloud_foundry/language_pack/helpers/plugins_installer'
require 'cloud_foundry/language_pack/helpers/readline_symlink'

module LanguagePack
  module Extensions
    def self.translate(host_url, original_filename)
      prefix = host_url.to_s.gsub(DEPENDENCIES_TRANSLATION_REGEX, DEPENDENCIES_TRANSLATION_DELIMITER)
      # WIP
      delimiter = (prefix.end_with? '_') ? '' : DEPENDENCIES_TRANSLATION_DELIMITER
      "#{prefix}#{delimiter}#{original_filename}"
    end
  end
end
