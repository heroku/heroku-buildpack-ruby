class LanguagePack::Helpers::NodeInstaller
  attr_reader :version

  def initialize
    nodebin = LanguagePack::Helpers::Nodebin.node_lts
    @version = nodebin["number"]
    @url     = nodebin["url"]
    @fetcher = LanguagePack::Fetcher.new("")
  end

  def binary_path
    node_folder(@version)
  end

  def install
    # Untar of this file produces artifacts that the app does not need to run.
    # If we ran this command in the app directory, we would have to manually
    # clean up un-used files. Instead we untar in a temp directory which
    # helps us avoid accidentally deleting code out of the user's slug by mistake.
    Dir.mktmpdir do |dir|
      node_bin = "#{binary_path}/bin/node"

      Dir.chdir(dir) do
        @fetcher.fetch_untar(@url, node_bin)
      end

      FileUtils.mv("#{dir}/#{node_bin}", ".")
    end
  end

  private
  def node_folder(version)
    "node-v#{version}-linux-x64"
  end
end
