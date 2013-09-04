require 'fileutils'
require 'language_pack/ruby'
require 'language_pack/fetcher'

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

      def vendor_dir
        @vendor_dir ||= File.expand_path("../../../tmp/#{LanguagePack::Ruby::BUNDLER_GEM_PATH}", __FILE__)
      end

      def fetch_bundler
        instrument 'fetch_bundler' do
          unless Dir.exists?(vendor_dir)
            FileUtils.mkdir_p(vendor_dir)
            fetcher = LanguagePack::Fetcher.new(LanguagePack::Base::VENDOR_URL)
            Dir.chdir(vendor_dir) do
              fetcher.fetch_untar("#{LanguagePack::Ruby::BUNDLER_GEM_PATH}.tgz")
            end
          end
        end

        vendor_dir
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
