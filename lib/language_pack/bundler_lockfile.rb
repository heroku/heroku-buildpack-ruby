module LanguagePack
  module BundlerLockfile
    module ClassMethods
      # checks if the Gemfile and Gemfile.lock exist
      def gemfile_lock?
        File.exist?('Gemfile') && File.exist?('Gemfile.lock')
      end

      def bundle
        @bundle ||= parse_bundle
      end

      def bundler_path
        @bundler_path ||= fetch_bundler
      end

      def fetch_bundler
        instrument 'fetch_bundler' do
          Dir.mktmpdir("bundler-").tap do |dir|
            Dir.chdir(dir) do
              system("curl #{LanguagePack::Base::VENDOR_URL}/#{LanguagePack::Ruby::BUNDLER_GEM_PATH}.tgz -s -o - | tar xzf -")
            end
          end
        end
      end

      def parse_bundle
        instrument 'parse_bundle' do
          $: << "#{bundler_path}/gems/bundler-#{LanguagePack::Ruby::BUNDLER_VERSION}/lib"
          require "bundler"
          Bundler::LockfileParser.new(File.read("Gemfile.lock"))
        end
      end
    end

    def bundle
      self.class.bundle
    end

    def bundler_path
      self.class.bundler_path
    end
  end
end
