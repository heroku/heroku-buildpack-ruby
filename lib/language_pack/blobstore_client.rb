require "language_pack"
require "net/http"
require "uri"
require "base64"

module LanguagePack::BlobstoreClient

  SHARE_URL_EXP = "1893484800" # expires on 2030 Jan-1

  BLOBSTORE_HOST = {
    :url => "http://blob.cfblob.com",
    :uid => "bb6a0c89ef4048a8a0f814e25385d1c5/user1"
  }

  def download_blob(oid, sig, sha, destination_file)
    unless oid && sig && sha
      raise "A valid object id, signature, and SHA are required"
    end

    File.open(destination_file, 'w') do |tf|
      url = BLOBSTORE_HOST[:url] + "/rest/objects/#{oid}?uid=" +
        URI::escape(BLOBSTORE_HOST[:uid]) +
        "&expires=#{SHARE_URL_EXP}&signature=#{URI::escape(sig)}"

      begin
        Net::HTTP.get_response(URI.parse(url)) do |response|
          unless response.is_a?(Net::HTTPSuccess)
            raise "Could not fetch object, %s/%s" % [response.code, response.body]
          end

          response.read_body do |segment|
            tf.write(segment)
          end
        end
      ensure
        tf.close
      end
      if file_checksum(destination_file) != sha
        raise "Checksum mismatch for downloaded blob"
      end
    end
  end

  def copy_cached_package(filename)
    puts "... copying #{filename} from the DEA cache"
    FileUtils.cp("/var/vcap/packages/ruby_bin/#{filename}", filename)
  end

  private
  def file_checksum(path)
    Digest::SHA1.file(path).hexdigest
  end
end