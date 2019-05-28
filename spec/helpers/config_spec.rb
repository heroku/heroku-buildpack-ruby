require 'spec_helper'

describe "Boot Strap Config" do
  it "matches the default ruby version" do
    require 'toml-rb'
    config = TomlRB.load_file("buildpack.toml")
    bootstrap_version = config["buildpack"]["ruby_version"]
    expect(bootstrap_version).to eq(LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER)

    urls = config["publish"]["Vendor"].map {|h| h["url"] if h["dir"] != "." }.compact
    urls.each do |url|
      expect(url.include?(bootstrap_version)).to be_truthy, "expected #{url.inspect} to include #{bootstrap_version.inspect} but it did not"
    end
  end
end
