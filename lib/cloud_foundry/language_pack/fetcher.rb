if Dir.exist?(DEPENDENCIES_PATH)
  require 'language_pack/fetcher'

  module LanguagePack
    class Fetcher
      def fetch(path)
        copy_file_from_dependencies_cache(path)
      end

      def fetch_untar(path, files_to_extract=nil)
        untar_file_from_dependencies_cache(path, files_to_extract)
      end

      private

      def copy_file_from_dependencies_cache(original_filename)
        dependency_filename = Extensions.translate @host_url, original_filename
        run!("cp #{File.join(DEPENDENCIES_PATH, dependency_filename)} #{original_filename}")
      end

      def untar_file_from_dependencies_cache(original_filename, files_to_extract="")
        dependency_filename = Extensions.translate @host_url, original_filename
        run!("tar zxf #{File.join(DEPENDENCIES_PATH, dependency_filename)} #{files_to_extract}")
      end
    end
  end
end
