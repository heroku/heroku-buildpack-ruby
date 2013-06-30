require "language_pack"
require "language_pack/base"

class LanguagePack::Metadata
  FOLDER = "vendor/heroku"

  def initialize(cache)
    if cache
      @cache = cache
      @cache.load FOLDER
    end
  end

  def read(key)
    full_key = "#{FOLDER}/#{key}"
    File.read(full_key) if exists?(key)
  end
  
  def exists?(key)
    full_key = "#{FOLDER}/#{key}"
    File.exists?(full_key) && !Dir.exists?(full_key)
  end

  def write(key, value, isave = true)
    FileUtils.mkdir_p(FOLDER)

    full_key = "#{FOLDER}/#{key}"
    File.open(full_key, 'w') {|f| f.puts value }
    save if isave
  end

  def save
    @cache ? @cache.store(FOLDER) : false
  end
end
