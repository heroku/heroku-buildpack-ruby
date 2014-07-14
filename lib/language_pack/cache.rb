require "pathname"
require "language_pack"

# Manipulates/handles contents of the cache directory
class LanguagePack::Cache
  # @param [String] path to the cache store
  def initialize(cache_path)
    @cache_base = Pathname.new(cache_path)
  end

  # removes the the specified path from the cache
  # @param [String] relative path from the base
  def clear(path)
    target = base.join(path)
    target.exist? && target.rmtree
  end

  # write cache contents
  # @param [String] path of contents to store. it will be stored using this a relative path from the base.
  # @param [String] relative path to store the cache contents, if nil it will assume the from path
  def store(from, path = nil)
    path ||= from
    copy from, base.join(path)
  end

  # load cache contents
  # @param [String] relative path of the cache contents
  # @param [String] path of where to store it locally, if nil, assume same relative path as the cache contents
  def load(path, dest = nil)
    dest ||= path
    copy base.join(path), dest
  end

  # copy cache contents
  # @param [String] source directory
  # @param [String] destination directory
  def copy(from, to)
    return false unless File.exist?(from)
    FileUtils.mkdir_p File.dirname(to)
    system("cp -a #{from}/. #{to}")
  end

  # copy contents between to places in the cache
  # @param [String] source cache directory
  # @param [String] destination directory
  def cache_copy(from,to)
    copy(base + from, base + to)
  end

  # check if the cache content exists
  # @param [String] relative path of the cache contents
  # @param [Boolean] true if the path exists in the cache and false if otherwise
  def exists?(path)
    base.join(path).exist?
  end
  alias :exist? :exists?

  def base
    @cache_base
  end
end
