require "pathname"
require "fileutils"
require "language_pack/cache"

# manipulating the `vendor/bundle` Bundler cache directory.
# supports storing the cache in a "stack" directory
class LanguagePack::BundlerCache
  attr_reader :bundler_dir

  # @param [LanguagePack::Cache] cache object
  # @param [String] stack buildpack is running on
  def initialize(cache, stack = ENV['STACK'])
    @cache       = cache
    @stack       = stack
    @bundler_dir = Pathname.new("vendor/bundle")
    @stack_dir   = Pathname.new(@stack).join(@bundler_dir)
  end

  # removes the bundler cache dir BOTH in the cache and local directory
  def clear
    @cache.clear(@stack_dir)
    @bundler_dir.rmtree
  end

  # writes cache contents to cache store
  def store
    @cache.store(@bundler_dir, @stack_dir)
  end

  # loads cache contents from the cache store
  def load
    @cache.load(@stack_dir, @bundler_dir)
  end
end
