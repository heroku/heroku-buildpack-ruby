require "pathname"
require "fileutils"
require "language_pack/cache"

# manipulating the `vendor/bundle` Bundler cache directory.
# supports storing the cache in a "stack" directory
class LanguagePack::YarnCache
  attr_reader :bundler_dir

  # @param [LanguagePack::Cache] cache object
  # @param [String] stack buildpack is running on
  def initialize(cache, stack = nil)
    @cache       = cache
    @stack       = stack
    @yarn_dir = Pathname.new("~/.yarn-cache")
    @stack_dir   = @stack ? Pathname.new(@stack) + @yarn_dir : @yarn_dir
  end

  # removes the bundler cache dir BOTH in the cache and local directory
  def clear(stack = nil)
    stack ||= @stack
    @cache.clear(stack)
    @yarn_dir.rmtree
  end

  # converts to cache directory to support stacks. only copy contents if the stack hasn't changed
  # @param [Boolean] denote if there's a stack change or not
  def convert_stack(stack_change)
    @cache.cache_copy(@yarn_dir, @stack_dir) unless stack_change
    @cache.clear(@yarn_dir)
  end

  # detects if using the non stack directory layout
  def old?
    @cache.exists?(@yarn_dir)
  end

  def exists?
    @cache.exists?(@stack_dir)
  end

  # writes cache contents to cache store
  def store
    @cache.store(@yarn_dir, @stack_dir)
  end

  # loads cache contents from the cache store
  def load
    @cache.load(@stack_dir, @yarn_dir)
  end
end
