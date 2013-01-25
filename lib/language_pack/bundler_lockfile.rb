module LanguagePack
  module BundlerLockfile
    # bootstraps bundler so we can use it before bundler is setup properlyLanguagePack::Ruby
    def bootstrap_bundler(&block)
      Dir.mktmpdir("bundler-") do |tmpdir|
        Dir.chdir(tmpdir) do
          system("curl #{LanguagePack::Base::VENDOR_URL}/#{LanguagePack::Ruby::BUNDLER_GEM_PATH}.tgz -s -o - | tar xzf -")
        end

        yield tmpdir
      end
    end
  end
end
