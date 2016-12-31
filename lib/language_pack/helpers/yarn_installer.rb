class LanguagePack::YarnInstaller

  YARN_SOURCE_URL = "https://yarnpkg.com/"

  def initialize(build_path, cache_path)
    @fetcher = LanguagePack::Fetcher.new(YARN_SOURCE_URL)
    @build_path = build_path
    @cache_path = cache_path
    puts "build path = #{@build_path}"
    puts "cache path = #{@cache_path}"
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
    @fetcher.fetch_untar(version, "dist/bin/")
    dir = "#{@cache_path}/yarn"
    FileUtils.mkdir_p(dir)
    FileUtils.cp_r("dist/bin/", dir)
    FileUtils.rm_rf("dist")
    # puts `export PATH=$PATH:/tmp/yarn/bin`
    puts "Echoing path"
    puts `echo $PATH`
    puts `ls #{dir}/bin`
  end

end
