require "net/http"
require "uri"
require "base64"

module LanguagePack
  module PackageFetcher

    VENDOR_URL = LanguagePack::Base::VENDOR_URL
    BLOBSTORE_CONFIG = File.join(File.dirname(__FILE__), "../../config/blobstore.yml")

    attr_writer :buildpack_cache_dir

    def buildpack_cache_dir
      @buildpack_cache_dir || "/var/vcap/packages/buildpack_cache"
    end

    def fetch_package(filename, url=VENDOR_URL)
      fetch_from_buildpack_cache(filename) ||
        fetch_from_blobstore(filename) ||
        fetch_from_curl(filename, url)
    end

    def fetch_package_and_untar(filename, url=VENDOR_URL)
      fetch_package(filename, url) && run("tar xzf #{filename}")
    end

    private

    def fetch_from_buildpack_cache(filename)
      file_path = File.join(buildpack_cache_dir, filename)
      return false unless File.exist?(file_path)
      puts "Copying #{filename} from the buildpack cache ..."
      FileUtils.cp(file_path, ".")
      true
    end

    def fetch_from_blobstore(filename)
      config = YAML.load_file File.expand_path(BLOBSTORE_CONFIG)
      return false if config["blobs"][filename].nil?
      oid = config["blobs"][filename]["oid"]
      sig = config["blobs"][filename]["sig"]
      sha = config["blobs"][filename]["sha"]

      unless oid && sig && sha
        puts "A valid object id, signature, and SHA are required"
        return false
      end

      puts "Downloading #{filename} from the blobstore ..."

      File.open(filename, 'w') do |tf|
        url = config["url"] + "/rest/objects/#{oid}?uid=" +
          URI::escape(config["uid"]) +
          "&expires=#{config["exp"]}&signature=#{URI::escape(sig)}"

        begin
          Net::HTTP.get_response(URI.parse(url)) do |response|
            unless response.is_a?(Net::HTTPSuccess)
              puts "Could not fetch object from blobstore (%s): %s/%s" % [filename, response.code, response.body]
              return false
            end

            response.read_body do |segment|
              tf.write(segment)
            end
          end
        ensure
          tf.close
        end
        if file_checksum(filename) != sha
          puts "Checksum mismatch for downloaded blob (%s)" % [filename]
          return false
        end
      end
      true
    end

    def fetch_from_curl(filename, url)
      puts "Downloading #{filename} from #{url} ..."
      run("curl #{url}/#{filename} -s -o #{filename}")
      File.exist?(filename)
    end

    def file_checksum(filename)
      Digest::SHA1.file(filename).hexdigest
    end
  end
end
