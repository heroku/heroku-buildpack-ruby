class LanguagePack::Helpers::DefaultCache
  include LanguagePack::ShellHelpers

  def initialize(version, cache_dir_missing, fetcher)
    @version           = version
    @cache_dir_missing = cache_dir_missing
    @fetcher           = fetcher
  end

  def can_load?
    @can_load ||= if @cache_dir_missing
      @fetcher.exist?(path)
    end
  end

  def load(msg = "Empty Cache detected, loading default bundler cache")
    return false unless can_load?
    puts msg
    @fetcher.fetch_untar(path)
  end

  def path
    "#{@version}-default-cache.tgz"
  end
end
