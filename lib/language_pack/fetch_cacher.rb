require "digest/sha2"
require "fileutils"

module LanguagePack
  class FetchCacher
    def initialize(cache_dir, prefix = nil)
      @cache_dir = Pathname.new cache_dir
      @cache_dir += File.basename prefix if prefix
    end

    def get(name, ext = "")
      (@cache_dir + (Digest::SHA256.hexdigest(name.to_s) + ext)).tap do |cache_file|
        FileUtils.mkdir_p cache_file.dirname.to_s
      end
    end
  end
end
