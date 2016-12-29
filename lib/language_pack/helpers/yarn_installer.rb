class LanguagePack::YarnInstaller

  YARN_SOURCE_URL = "https://yarnpkg.com/"

  def initialize(build_path, cache_path)
    @fetcher = LanguagePack::Fetcher.new(YARN_SOURCE_URL)
    @build_path = build_path
  end

  def version
    "latest.tar.gz"
  end


  def binary_path
    if @legacy
      LEGACY_BINARY_PATH
    else
      MODERN_BINARY_PATH
    end
  end

  def install
    FileUtils.mkdir_p("/tmp/yarn")
    @fetcher.fetch_untar(version, "/tmp/yarn")
    FileUtils.mv("/tmp/yarn/dist/bin/yarnpkg", "#{@build_path}/vendor/yarnpkg")
    FileUtils.rm_rf("/tmp/yarn")
  end

end
