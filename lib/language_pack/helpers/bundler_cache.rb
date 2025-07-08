require "pathname"
require "fileutils"
require "language_pack/cache"

# manipulating the `vendor/bundle` Bundler cache directory.
# supports storing the cache in a "stack" directory
class LanguagePack::BundlerCache

  # @param [LanguagePack::Cache] cache object
  # @param [String] stack buildpack is running on
  def initialize(cache:, stack:, app_path:)
    @cache       = cache
    @stack       = stack
    @app_path = app_path
    @app_folder = Pathname.new("vendor/bundle")
    @cache_folder   = Pathname.new(@stack).join(@app_folder)
  end

  # removes the bundler cache dir BOTH in the cache and local directory
  def clear(stack = nil)
    stack ||= @stack
    @cache.clear(stack)
    @app_folder.rmtree
  end

  def exists?
    @cache.exists?(@cache_folder)
  end

  # writes cache contents to cache store
  def app_to_cache
    @cache.clear(@cache_folder)
    @cache.app_to_cache(
      dir: @app_folder,
      rename: @cache_folder,
      force: true
    )
  end

  # loads cache contents from the cache store
  def cache_to_app
    @cache.cache_to_app(
      dir: @cache_folder,
      rename: @app_folder,
      force: true
    )
  end
end
