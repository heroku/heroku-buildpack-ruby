class LanguagePack::Helpers::YarnInstaller
  attr_reader :version

  def initialize
    # Grab latest yarn, until release practice stabilizes
    # https://github.com/yarnpkg/yarn/issues/376#issuecomment-253366910
    nodebin  = LanguagePack::Helpers::Nodebin.yarn("latest")
    @version = nodebin["number"]
    @url     = nodebin["url"]
    @fetcher = LanguagePack::Fetcher.new("")
  end

  def name
    "yarn-v#{@version}"
  end

  def binary_path
    "#{name}/bin/"
  end

  def install
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        @fetcher.fetch_untar(@url)
      end

      FileUtils.mv(File.join(dir, name), name)
    end
  end
end
