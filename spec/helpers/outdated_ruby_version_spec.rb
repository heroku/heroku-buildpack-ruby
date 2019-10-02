require "spec_helper"

describe LanguagePack::Helpers::OutdatedRubyVersion do
  let(:stack) { "heroku-16" }
  let(:fetcher) { LanguagePack::Fetcher.new(LanguagePack::Base::VENDOR_URL, stack) }

  it "finds the latest version on a stack" do
    ruby_version = LanguagePack::RubyVersion.new("ruby-2.2.5")
    outdated = LanguagePack::Helpers::OutdatedRubyVersion.new(
      current_ruby_version: ruby_version,
      fetcher: fetcher
    )

    outdated.call
    expect(outdated.suggested_ruby_minor_version).to eq("2.2.10")
    expect(outdated.eol?).to eq(true)
    expect(outdated.maybe_eol?).to eq(true)
  end

  it "detects returns original ruby version when using the latest" do
    ruby_version = LanguagePack::RubyVersion.new("ruby-2.2.10")
    outdated = LanguagePack::Helpers::OutdatedRubyVersion.new(
      current_ruby_version: ruby_version,
      fetcher: fetcher
    )

    outdated.call
    expect(outdated.suggested_ruby_minor_version).to eq("2.2.10")
    expect(outdated.latest_minor_version?).to be_truthy
  end

  it "Doesn't do anything when using a patch significant version" do
    ruby_version = LanguagePack::RubyVersion.new("ruby-1.9.3p123")
    outdated = LanguagePack::Helpers::OutdatedRubyVersion.new(
      current_ruby_version: ruby_version,
      fetcher: fetcher
    )

    outdated.call
    expect(outdated.can_check?).to eq(false)
    expect(outdated.suggested_ruby_minor_version).to eq(nil)
  end

  it "recommends a non EOL version of Ruby" do
    ruby_version_one = LanguagePack::RubyVersion.new("ruby-2.1.10")
    ruby_version_two = LanguagePack::RubyVersion.new("ruby-2.2.10")

    outdated_one = LanguagePack::Helpers::OutdatedRubyVersion.new(
      current_ruby_version: ruby_version_one,
      fetcher: fetcher
    )
    outdated_two = LanguagePack::Helpers::OutdatedRubyVersion.new(
      current_ruby_version: ruby_version_two,
      fetcher: fetcher
    )

    outdated_one.call
    outdated_two.call

    expect(outdated_one.eol?).to be_truthy
    expect(outdated_one.maybe_eol?).to be_truthy

    expect(outdated_two.eol?).to be_truthy
    expect(outdated_one.maybe_eol?).to be_truthy

    suggested_one = outdated_one.suggest_ruby_eol_version
    expect(suggested_one).to eq(outdated_two.suggest_ruby_eol_version)
    expect(suggested_one.chars.last).to eq("x") # i.e. 2.5.x

    actual = Gem::Version.new(suggested_one)
    expect(actual).to be > Gem::Version.new("2.4.x")
  end

  it "does not recommend EOL for recent ruby version" do
    ruby_version = LanguagePack::RubyVersion.new("ruby-2.2.10")

    outdated = LanguagePack::Helpers::OutdatedRubyVersion.new(
      current_ruby_version: ruby_version,
      fetcher: fetcher
    )

    outdated.call

    good_version = outdated.suggest_ruby_eol_version.sub("x", "0")
    ruby_version = LanguagePack::RubyVersion.new("ruby-#{good_version}")

    outdated = LanguagePack::Helpers::OutdatedRubyVersion.new(
      current_ruby_version: ruby_version,
      fetcher: fetcher
    )
    outdated.call

    expect(outdated.eol?).to be_falsey
    expect(outdated.maybe_eol?).to be_falsey
  end

  it "can call eol? on the latest Ruby version" do
    ruby_version = LanguagePack::RubyVersion.new("ruby-2.6.0")

    new_fetcher = fetcher.dup
    def new_fetcher.exists?(value); false; end

    outdated = LanguagePack::Helpers::OutdatedRubyVersion.new(
      current_ruby_version: ruby_version,
      fetcher: new_fetcher
    )

    outdated.call

    expect(outdated.eol?).to be_falsey
    expect(outdated.maybe_eol?).to be_falsey
  end

end

