require "pathname"
require "fileutils"
require "language_pack/cache"

# manipulating the `vendor/bundle` Bundler cache directory.
# supports storing the cache in a "stack" directory
class LanguagePack::BundlerCache
  attr_reader :bundler_dir

  # @param [LanguagePack::Cache] cache object
  # @param [String] stack buildpack is running on
  def initialize(cache, stack = nil)
    @cache       = cache
    @stack       = stack
    @bundler_dir = Pathname.new("vendor/bundle")
    @stack_dir   = @stack ? Pathname.new(@stack) + @bundler_dir : @bundler_dir
  end

  # removes the bundler cache dir BOTH in the cache and local directory
  def clear(stack = nil)
    stack ||= @stack
    @cache.clear(stack)
    @bundler_dir.rmtree
  end

  # converts to cache directory to support stacks. only copy contents if the stack hasn't changed
  # @param [Boolean] denote if there's a stack change or not
  def convert_stack(stack_change)
    if !stack_change
      @cache.cache_to_cache(
        dir: @bundler_dir,
        rename: @stack_dir,
        force: true
      )
    end
    @cache.clear(@bundler_dir)
  end

  # detects if using the non stack directory layout
  def old?
    @cache.exists?(@bundler_dir)
  end

  def exists?
    @cache.exists?(@stack_dir)
  end

  # writes cache contents to cache store
  def app_to_cache
    @cache.clear(@stack_dir)
    @cache.app_to_cache(
      dir: @bundler_dir,
      rename: @stack_dir,
      force: true
    )
  end

  # loads cache contents from the cache store
  def cache_to_app
    @cache.cache_to_app(
      dir: @stack_dir,
      rename: @bundler_dir,
      force: true
    )
  end
end
