class LanguagePack::YarnInstaller

  YARN_SOURCE_URL = "https://yarnpkg.com/"

  def initialize(build_path, cache_path)
    @fetcher = LanguagePack::Fetcher.new(YARN_SOURCE_URL)
    @build_path = build_path
    puts "build path = #{@build_path}"
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
    @fetcher.fetch_untar(version, "dist/bin/yarnpkg")
    FileUtils.mv("dist/bin/yarnpkg", "/tmp/yarnpkg")
    FileUtils.rm_rf("dist")
    puts `export PATH=$PATH:tmp`
    puts `echo $PATH`
    puts `ls /tmp`
  end

end
