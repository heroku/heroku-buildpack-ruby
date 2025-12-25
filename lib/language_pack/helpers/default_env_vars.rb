
module LanguagePack::Helpers::DefaultEnvVars
  # Returns a hash of default environment variables for the given inputs
  #
  # Values will be written to disk as defaults
  #
  # i.e. `export RAILS_ENV=${RAILS_ENV:-production}`
  #
  # Therefore it's important that we don't return any values from user provided config vars
  # or customers will not be able to `heroku config:unset` them.
  #
  # @param is_jruby [Boolean] whether the app is using JRuby
  # @param rack_version [Gem::Version] the version of the rack gem
  # @param rails_version [Gem::Version] the version of the rails gem
  # @param secret_key_base [String] the secret key base for the app
  # @param environment_name [String] the environment name to use for RACK_ENV/RAILS_ENV
  # @return [Hash] a hash of default environment variables
  def self.call(is_jruby:, rack_version: , rails_version:, secret_key_base:, environment_name:)
    out = {}
    out["LANG"] = "en_US.UTF-8"
    out["PUMA_PERSISTENT_TIMEOUT"] = "95"

    if is_jruby
      out["JRUBY_OPTS"] = "-Xcompile.invokedynamic=false"
    end

    if rack_version
      out["RACK_ENV"] = environment_name
    end

    if rails_version
      out["RAILS_ENV"] = environment_name
    end

    if rails_version&. >= Gem::Version.new("4.1.0.beta1")
      if secret_key_base = secret_key_base&.to_s
        out["SECRET_KEY_BASE"] = secret_key_base
      else
        raise ArgumentError, "secret_key_base is required for rails 4.1+. Provided: #{secret_key_base.inspect}"
      end
    end

    if rails_version&. >= Gem::Version.new("4.2.0")
      out["RAILS_SERVE_STATIC_FILES"] = "enabled"
    end

    if rails_version&. >= Gem::Version.new("5.0.0")
      out["RAILS_LOG_TO_STDOUT"] = "enabled"
    end

    out
  end
end
