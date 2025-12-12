require 'spec_helper'

describe "Metadata" do
  it "can read and write to the metadata" do
    Dir.mktmpdir do |dir|
      metadata = LanguagePack::Metadata.new(cache_path: dir)
      expect(metadata.empty?).to be_truthy

      expect(metadata.exists?("test")).to be_falsey
      metadata.write("test", "test")

      expect(metadata.exists?("test")).to be_truthy
      expect(metadata.read("test")).to eq("test")
      expect(metadata.empty?).to be_falsey
    end
  end

  it "can write a value conditionally" do
    Dir.mktmpdir do |dir|
      metadata = LanguagePack::Metadata.new(cache_path: dir)
      called = false

      expect(metadata.empty?).to be_truthy
      expect(metadata.exists?("test")).to be_falsey
      metadata.fetch("test") do
        called = true
        "test"
      end
      expect(metadata.read("test")).to eq("test")
      expect(called).to be_truthy
      expect(metadata.empty?).to be_falsey
    end
  end
end
