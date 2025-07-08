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
    @new_app = !@cache.exists?(FOLDER)
    @metadata_path.mkpath
    @cache.cache_to_app(dir: FOLDER, force: true)
  end

  # Cache will not exist on a new app
  def new_app?
    @new_app
  end

  def read(key)
    path = @metadata_path.join(key)
    path.read.strip if path.file?
  end

  def exists?(key)
    @metadata_path.join(key).file?
  end

  def write(key, value, isave = true)
    @metadata_path.join(key).write(value)
    save if isave

    return true
  end

  def touch(key)
    write(@metadata_path.join(key), "true")
  end

  def fetch(key)
    return read(key) if exists?(key)

    value = yield

    write(key, value.to_s)
    return value
  end

  def save(path = @metadata_path)
    @cache.app_to_cache(dir: FOLDER, force: true)
  end
end
