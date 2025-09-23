# frozen_string_literal: true

require "spec_helper"

describe LanguagePack::Helpers::PumaWarnError do
  it "warns about Router 2.0 compatability" do
    puma_warn_error = LanguagePack::Helpers::PumaWarnError.new(
      puma_version: Gem::Version.new("6.0.0"),
      env: {}
    )
    expect(puma_warn_error.warnings.join).to include("Heroku recommends using Puma 7.0.3+ for compatability with Router 2.0")
  end

  it "errors if incompatible version with persistent timeout env var" do
    puma_warn_error = LanguagePack::Helpers::PumaWarnError.new(
      puma_version: Gem::Version.new("7.0.0"),
      env: {}
    )
    expect(puma_warn_error.error).to include("known issue with the `PUMA_PERSISTENT_TIMEOUT`")

    puma_warn_error = LanguagePack::Helpers::PumaWarnError.new(
      puma_version: Gem::Version.new("7.0.1"),
      env: {}
    )
    expect(puma_warn_error.error).to include("known issue with the `PUMA_PERSISTENT_TIMEOUT`")

    puma_warn_error = LanguagePack::Helpers::PumaWarnError.new(
      puma_version: Gem::Version.new("7.0.2"),
      env: {}
    )
    expect(puma_warn_error.error).to include("known issue with the `PUMA_PERSISTENT_TIMEOUT`")

    puma_warn_error = LanguagePack::Helpers::PumaWarnError.new(
      puma_version: Gem::Version.new("7.0.3"),
      env: {}
    )
    expect(puma_warn_error.error).to be_nil
    expect(puma_warn_error.warnings).to eq([])
  end

  it "warns, but does not error if customer manually set PUMA_PERSISTENT_TIMEOUT" do
    puma_warn_error = LanguagePack::Helpers::PumaWarnError.new(
      puma_version: Gem::Version.new("7.0.0"),
      env: { "PUMA_PERSISTENT_TIMEOUT" => "95" }
    )
    expect(puma_warn_error.error).to be_nil
    expect(puma_warn_error.warnings.join).to include("Heroku recommends using Puma 7.0.3+ for compatability with Router 2.0")
  end
end
