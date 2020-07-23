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

  def [](key)
    read(key)
  end

  def []=(key, value)
    write(key, value)
  end

  def read(key)
    full_key = "#{FOLDER}/#{key}"
    File.read(full_key).chomp if exists?(key)
  end

  def exists?(key)
    full_key = "#{FOLDER}/#{key}"
    File.exists?(full_key) && !Dir.exists?(full_key)
  end
  alias_method :include?, :exists?

  def write(key, value, isave = true)
    FileUtils.mkdir_p(FOLDER)

    full_key = "#{FOLDER}/#{key}"
    File.open(full_key, 'w') {|f| f.puts value }
    save if isave

    return true
  end

  def touch(key)
    write(key, "true")
  end

  def fetch(key)
    return read(key) if exists?(key)

    value = yield

    write(key, value.to_s)
    return value
  end

  def save(file = FOLDER)
    @cache ? @cache.add(file) : false
  end
end
