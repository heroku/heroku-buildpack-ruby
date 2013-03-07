module LanguagePack
  module BundlerLockfile
    # checks if the Gemfile and Gemfile.lock exist
    def gemfile_lock?
      File.exist?('Gemfile') && File.exist?('Gemfile.lock')
    end

    def bundle
      @bundle ||= init_bundle
    end

    def bundler_path
      @bundler_path ||= Dir.mktmpdir("bundler-")
    end

    def init_bundle
      Dir.chdir(bundler_path) do
        system("curl #{LanguagePack::Base::VENDOR_URL}/#{LanguagePack::Ruby::BUNDLER_GEM_PATH}.tgz -s -o - | tar xzf -")
      end
      $: << "#{bundler_path}/gems/bundler-#{LanguagePack::Ruby::BUNDLER_VERSION}/lib"
      require "bundler"
      Bundler::LockfileParser.new(File.read("Gemfile.lock"))
    end
  end
end
