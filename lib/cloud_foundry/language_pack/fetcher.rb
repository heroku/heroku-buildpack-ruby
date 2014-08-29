if Dir.exist?(DEPENDENCIES_PATH)
  require 'language_pack/fetcher'

  module LanguagePack
    class Fetcher
      def fetch(path)
        copy_file_from_dependencies_cache(path)
      end

      def fetch_untar(path)
        untar_file_from_dependencies_cache(path)
      end

      private

      def copy_file_from_dependencies_cache(original_filename)
        dependency_filename = Extensions.translate @host_url, original_filename
        run!("cp #{File.join(DEPENDENCIES_PATH, dependency_filename)} #{original_filename}")
      end

      def untar_file_from_dependencies_cache(original_filename)
        original_filename = "#{original_filename}.mac" if ruby_200_on_OSX(original_filename)

        dependency_filename = Extensions.translate @host_url, original_filename
        run!("tar zxf #{File.join(DEPENDENCIES_PATH, dependency_filename)}")
      end

      def ruby_200_on_OSX(original_filename)
        original_filename.match('ruby-2.0.0') && `uname -s`.match('Darwin')
      end
    end
  end
end
