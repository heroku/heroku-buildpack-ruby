require "pathname"
require "language_pack"

class LanguagePack::Cache
  def initialize(cache_path)
    @cache_base = Pathname.new(cache_path)
  end

  # removes the the specified
  # @param [String] relative path from the cache_base
  def clear(path)
    target = (@cache_base + path)
    target.exist? && target.rmtree
  end

  # write cache contents
  # @param [String] path of contents to store. it will be stored using this a relative path from the cache_base.
  # @param [Boolean] defaults to true. if set to true, the cache store directory will be cleared before writing to it.
  def store(path, clear_first=true)
    clear(path) if clear_first
    copy path, (@cache_base + path)
  end

  # load cache contents
  # @param [String] relative path of the cache contents
  def load(path)
    copy (@cache_base + path), path
  end

  # copy cache contents
  # @param [String] source directory
  # @param [String] destination directory
  def copy(from, to)
    return false unless File.exist?(from)
    FileUtils.mkdir_p File.dirname(to)
    system("cp -a #{from}/. #{to}")
  end

  # check if the cache content exists
  # @param [String] relative path of the cache contents
  # @param [Boolean] true if the path exists in the cache and false if otherwise
  def exists?(path)
    File.exists?(@cache_base + path)
  end
end
