
require 'spec_helper'

describe LanguagePack::Helpers::DefaultEnvVars do
  it "returns when everything falsey" do
    env = LanguagePack::Helpers::DefaultEnvVars.call(
      is_jruby: nil,
      rack_version: nil,
      rails_version: nil,
      secret_key_base: nil
    )

    expect(env).to eq({
      "LANG" => "en_US.UTF-8",
      "PUMA_PERSISTENT_TIMEOUT" => "95",
    })
  end

  it "jruby" do
    env = LanguagePack::Helpers::DefaultEnvVars.call(
      is_jruby: true,
      rack_version: nil,
      rails_version: nil,
      secret_key_base: nil
    )

    expect(env).to eq({
      "LANG" => "en_US.UTF-8",
      "PUMA_PERSISTENT_TIMEOUT" => "95",
      "JRUBY_OPTS" => "-Xcompile.invokedynamic=false"
    })
  end

  it "rack" do
    env = LanguagePack::Helpers::DefaultEnvVars.call(
      is_jruby: false,
      rack_version: Gem::Version.new("2.0.0"),
      rails_version: nil,
      secret_key_base: nil
    )

    expect(env).to eq({
      "LANG" => "en_US.UTF-8",
      "PUMA_PERSISTENT_TIMEOUT" => "95",
      "RACK_ENV" => "production"
    })
  end

    # if rails_version&. >= Gem::Version.new("4.1.0.beta1")
    #   out["SECRET_KEY_BASE"] = secret_key_base
    # end

    # if rails_version&. >= Gem::Version.new("4.2.0")
    #   out["RAILS_SERVE_STATIC_FILES"] = "enabled"
    # end

    # if rails_version&. >= Gem::Version.new("5.0.0")
    #   out["RAILS_LOG_TO_STDOUT"] = "enabled"
    # end

  it "rails 4.1" do
    env = LanguagePack::Helpers::DefaultEnvVars.call(
      is_jruby: false,
      rack_version: Gem::Version.new("2.0.0"),
      rails_version: Gem::Version.new("4.1.0.beta1"),
      secret_key_base: "secret_key_base"
    )

    expect(env).to eq({
      "LANG" => "en_US.UTF-8",
      "PUMA_PERSISTENT_TIMEOUT" => "95",
      "RACK_ENV" => "production",
      "RAILS_ENV" => "production",
      "SECRET_KEY_BASE" => "secret_key_base"
    })
  end

  it "rails 4.2" do
    env = LanguagePack::Helpers::DefaultEnvVars.call(
      is_jruby: false,
      rack_version: Gem::Version.new("2.0.0"),
      rails_version: Gem::Version.new("4.2.0"),
      secret_key_base: "secret_key_base"
    )

    expect(env).to eq({
      "LANG" => "en_US.UTF-8",
      "PUMA_PERSISTENT_TIMEOUT" => "95",
      "RACK_ENV" => "production",
      "RAILS_ENV" => "production",
      "SECRET_KEY_BASE" => "secret_key_base",
      "RAILS_SERVE_STATIC_FILES" => "enabled"
    })
  end

  it "rails 5.0" do
    env = LanguagePack::Helpers::DefaultEnvVars.call(
      is_jruby: false,
      rack_version: Gem::Version.new("2.0.0"),
      rails_version: Gem::Version.new("5.0.0"),
      secret_key_base: "secret_key_base"
    )

    expect(env).to eq({
      "LANG" => "en_US.UTF-8",
      "PUMA_PERSISTENT_TIMEOUT" => "95",
      "RACK_ENV" => "production",
      "RAILS_ENV" => "production",
      "SECRET_KEY_BASE" => "secret_key_base",
      "RAILS_SERVE_STATIC_FILES" => "enabled",
      "RAILS_LOG_TO_STDOUT" => "enabled"
    })
  end

  it "raises an error if secret_key_base is not provided and rails 4.1+" do
    expect {
      LanguagePack::Helpers::DefaultEnvVars.call(
        is_jruby: false,
        rack_version: Gem::Version.new("2.0.0"),
        rails_version: Gem::Version.new("4.1.0"),
        secret_key_base: nil
      )
    }.to raise_error(ArgumentError)
  end
end
