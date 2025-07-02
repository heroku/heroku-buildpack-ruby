require "language_pack"
require "language_pack/base"

# Stores durable information about the build
#
# For example, SECRET_KEY_BASE, which is used when signing Rails cookies.
# Stores other build-related information, such as the last version of Bundler requested.
#
# The LanguagePack::Cache is responsible for moving files to/from the cache dir
# provided to the buildpack. This class is responsible for updating files on disk
# and using the LanguagePack::Cache to manage loading/saving data from
# builds.
class LanguagePack::Metadata
  FOLDER = "vendor/heroku"

  def initialize(cache: , app_path: )
    @cache = cache
    @metadata_path = app_path.join(FOLDER)
    @cache.load(FOLDER, @metadata_path)
  end

  def read(key)
    full_key = "#{FOLDER}/#{key}"
    File.read(full_key).strip if exists?(key)
  end

  def exists?(key)
    full_key = "#{FOLDER}/#{key}"
    File.exist?(full_key) && !Dir.exist?(full_key)
  end

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
    @cache.add(file)
  end
end
