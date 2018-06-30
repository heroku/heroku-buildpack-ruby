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
        track cache_file
      end
    end

    def clean
      track_file = @cache_dir + '.track'
      return unless track_file.exist?
      tracked_files = track_file.each_line.map(&:chomp)
      untracked_files = Dir[@cache_dir + "*"] - tracked_files
      untracked_files.each do |file|
        FileUtils.rm file
      end
      track_file.delete
    end

    private

    def track(filename)
      track_file = @cache_dir + '.track'
      track_file.open('a') { |f| f.puts filename.to_s }
    end
  end
end
