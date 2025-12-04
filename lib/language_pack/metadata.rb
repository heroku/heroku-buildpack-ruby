require "language_pack"
require "language_pack/base"

# Store data about the build in the cache
#
# Uses `<cache_path>/vendor/heroku` as the metadata directory. Which
# is special cased in cache clearing code to be durable. This allows
# for persistant generated data such as SECRET_KEY_BASE that would otherwise
# cause session invalidation if it changed unexpectedly between deploys.
class LanguagePack::Metadata
  def initialize(cache_path: )
    @dir = Pathname(cache_path)
      .join("vendor")
      .join("heroku")
      .tap(&:mkpath)
  end

  def empty?
    @dir.children.empty?
  end

  def try_read(key)
    if exists?(key)
      read(key)
    else
      nil
    end
  end

  def read(key)
    @dir.join(key).read&.strip
  end

  def exists?(key)
    @dir.join(key).file?
  end

  def write(key, value)
    @dir.join(key).write(value)
  end

  def fetch(key)
    if exists?(key)
      read(key)
    else
      value = yield
      write(key, value.to_s)
      value
    end
  end
end
