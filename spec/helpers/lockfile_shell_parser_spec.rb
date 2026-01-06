require 'spec_helper'

describe LanguagePack::Helpers::LockfileShellParser do
  describe ".call" do
    it "parses gem specs from a Gemfile.lock" do
      Dir.mktmpdir do |dir|
        lockfile_path = Pathname(dir).join("Gemfile.lock")
        lockfile_path.write(<<~EOF)
          GEM
            remote: https://rubygems.org/
            specs:
              rake (13.2.1)

          PLATFORMS
            arm64-darwin-22
            ruby
            x86_64-linux

          DEPENDENCIES
            rake

          RUBY VERSION
             ruby 3.3.9

          BUNDLED WITH
             2.7.9
        EOF

        specs = LanguagePack::Helpers::LockfileShellParser.call(lockfile_path: lockfile_path)

        expect(specs["rake"]).to eq(Gem::Version.new("13.2.1"))
      end
    end

    it "parses multiple gems from a Gemfile.lock" do
      Dir.mktmpdir do |dir|
        lockfile_path = Pathname(dir).join("Gemfile.lock")
        lockfile_path.write(<<~EOF)
          GEM
            remote: https://rubygems.org/
            specs:
              concurrent-ruby (1.2.3)
              i18n (1.14.1)
                concurrent-ruby (~> 1.0)
              rack (3.0.8)

          PLATFORMS
            ruby

          DEPENDENCIES
            i18n
            rack

          BUNDLED WITH
             2.7.9
        EOF

        specs = LanguagePack::Helpers::LockfileShellParser.call(lockfile_path: lockfile_path)

        expect(specs["concurrent-ruby"]).to eq(Gem::Version.new("1.2.3"))
        expect(specs["i18n"]).to eq(Gem::Version.new("1.14.1"))
        expect(specs["rack"]).to eq(Gem::Version.new("3.0.8"))
      end
    end

    it "returns an empty hash for a lockfile with no gems" do
      Dir.mktmpdir do |dir|
        lockfile_path = Pathname(dir).join("Gemfile.lock")
        lockfile_path.write(<<~EOF)
          GEM
            remote: https://rubygems.org/
            specs:

          PLATFORMS
            ruby

          BUNDLED WITH
             2.7.9
        EOF

        specs = LanguagePack::Helpers::LockfileShellParser.call(lockfile_path: lockfile_path)

        expect(specs).to eq({})
      end
    end
  end
end

