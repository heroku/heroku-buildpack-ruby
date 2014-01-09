require 'spec_helper'

describe "DefaultCache" do

  it "Works with 2.0.0p353" do
    version = "2.0.0-p353"
    fetcher = LanguagePack::Fetcher.new(LanguagePack::Base::VENDOR_URL)
    cache   = LanguagePack::Helpers::DefaultCache.new("ruby-#{version}",
                                                            true,
                                                            fetcher)
    expect(cache.can_load?).to be_true
  end

  it "Works with 2.1.0" do
    version = "2.1.0"
    fetcher = LanguagePack::Fetcher.new(LanguagePack::Base::VENDOR_URL)
    cache   = LanguagePack::Helpers::DefaultCache.new("ruby-#{version}",
                                                            true,
                                                            fetcher)
    expect(cache.can_load?).to be_true
  end

  it "Does not works with 1.8.7 raw" do
    version = "1.8.7"
    fetcher = LanguagePack::Fetcher.new(LanguagePack::Base::VENDOR_URL)
    cache   = LanguagePack::Helpers::DefaultCache.new("ruby-#{version}",
                                                            true,
                                                            fetcher)
    expect(cache.can_load?).to be_false
  end
end

