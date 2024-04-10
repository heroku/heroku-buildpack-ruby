require "yaml"
require "language_pack/shell_helpers"

module LanguagePack
  class Fetcher
    class FetchError < StandardError; end

    include ShellHelpers

    def initialize(host_url, stack: nil, arch: nil)
      @host_url = Pathname.new(host_url)
      # File.basename prevents accidental directory traversal
      @host_url += File.basename(stack) if stack
      @host_url += File.basename(arch) if arch
    end

    def exists?(path, max_attempts = 1)
      curl = curl_command("-I #{@host_url.join(path)}")
      run!(curl, error_class: FetchError, max_attempts: max_attempts, silent: true)
    rescue FetchError
      false
    end

    def fetch(path)
      curl = curl_command("-O #{@host_url.join(path)}")
      run!(curl, error_class: FetchError)
    end

    def fetch_untar(path, files_to_extract = nil)
      curl = curl_command("#{@host_url.join(path)} -s -o")
      run! "#{curl} - | tar zxf - #{files_to_extract}",
        error_class: FetchError,
        max_attempts: 3
    end

    def fetch_bunzip2(path, files_to_extract = nil)
      curl = curl_command("#{@host_url.join(path)} -s -o")
      run!("#{curl} - | tar jxf - #{files_to_extract}", error_class: FetchError)
    end

    private
    def curl_command(command)
      "set -o pipefail; curl -L --fail --retry 5 --retry-delay 1 --connect-timeout #{curl_connect_timeout_in_seconds} --max-time #{curl_timeout_in_seconds} #{command}"
    end

    def curl_timeout_in_seconds
      env('CURL_TIMEOUT') || 30
    end

    def curl_connect_timeout_in_seconds
      env('CURL_CONNECT_TIMEOUT') || 3
    end
  end
end
