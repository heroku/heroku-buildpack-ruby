require 'spec_helper'

describe "Boot Strap Config" do
  it "matches toml config" do
    require 'toml-rb'
    config = TomlRB.load_file("buildpack.toml")
    bootstrap_version = config["buildpack"]["ruby_version"]
    expect(bootstrap_version).to eq(LanguagePack::RubyVersion::BOOTSTRAP_VERSION_NUMBER)

    expect(`ruby -v`).to match(Regexp.escape(LanguagePack::RubyVersion::BOOTSTRAP_VERSION_NUMBER))

    # bootstrap_version = Gem::Version.new(LanguagePack::RubyVersion::BOOTSTRAP_VERSION_NUMBER)
    # default_version = Gem::Version.new(LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER)

    # expect(bootstrap_version).to be >= default_version
  end
end
