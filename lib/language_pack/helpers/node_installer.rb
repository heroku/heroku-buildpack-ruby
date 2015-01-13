class LanguagePack::NodeInstaller
  MODERN_NODE_VERSION = "0.10.30"
  MODERN_BINARY_PATH  = "node-v#{MODERN_NODE_VERSION}-linux-x64"

  LEGACY_NODE_VERSION = "0.4.7"
  LEGACY_BINARY_PATH = "node-#{LEGACY_NODE_VERSION}"

  NODEJS_BASE_URL     = "http://s3pository.heroku.com/node/v#{MODERN_NODE_VERSION}/"

  def initialize(stack)
    @fetchers = {
      modern: LanguagePack::Fetcher.new(NODEJS_BASE_URL),
      legacy: LanguagePack::Fetcher.new(LanguagePack::Base::VENDOR_URL, LanguagePack::Base::DEFAULT_LEGACY_STACK)
    }
    @legacy   = stack == LanguagePack::Base::DEFAULT_LEGACY_STACK
  end

  def version
    if @legacy
      LEGACY_NODE_VERSION
    else
      MODERN_NODE_VERSION
    end
  end

  def binary_path
    if @legacy
      LEGACY_BINARY_PATH
    else
      MODERN_BINARY_PATH
    end
  end

  def install
    if @legacy
      @fetchers[:legacy].fetch_untar("#{LEGACY_BINARY_PATH}.tgz")
    else
      node_bin = "#{MODERN_BINARY_PATH}/bin/node"
      @fetchers[:modern].fetch_untar("#{MODERN_BINARY_PATH}.tar.gz", "#{MODERN_BINARY_PATH}/bin/node")
      FileUtils.mv(node_bin, ".")
      FileUtils.rm_rf(MODERN_BINARY_PATH)
    end
  end
end
