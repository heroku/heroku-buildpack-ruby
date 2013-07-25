require "yaml"
require "language_pack/shell_helpers"

module LanguagePack
  class Fetcher
    include ShellHelpers

    def initialize(host_url)
      @config   = load_config
      @host_url = fetch_cdn(host_url)
    end

    def fetch(path)
      run("curl -O #{@host_url}/#{path}")
    end

    def fetch_untar(path)
      run("curl #{@host_url}/#{path} -s -o - | tar zxf -")
    end

    def fetch_bunzip2(path)
      run("curl #{@host_url}/#{path} -s -o - | tar jxf -")
    end

    private
    def load_config
      YAML.load_file(File.expand_path("../../../config/cdn.yml", __FILE__))
    end

    def fetch_cdn(url)
      cdn = @config[url]
      cdn.nil? ? url : cdn
    end
  end
end
