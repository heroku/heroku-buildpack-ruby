require 'spec_helper'

describe "Boot Strap Config" do
  it "matches the default ruby version" do
    require 'toml-rb'
    config = TomlRB.load_file("buildpack.toml")
    bootstrap_version = config["buildpack"]["ruby_version"]
    expect(bootstrap_version).to eq(LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER)
  end
end
