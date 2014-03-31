DEPENDENCIES_PATH = File.expand_path("../../dependencies", File.expand_path($0))

if Dir.exist?(DEPENDENCIES_PATH)
  require 'language_pack/fetcher'

  module LanguagePack
    class Fetcher
      def fetch(path)
        run!("cp #{File.join(DEPENDENCIES_PATH, path)} .")
      end

      def fetch_untar(path)
        path = "#{path}.mac" if path.match('ruby-2.0.0') && `uname -s`.match('Darwin')
        run!("tar zxf #{File.join(DEPENDENCIES_PATH, path)}")
      end
    end
  end
end