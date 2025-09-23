# frozen_string_literal: true

# Checks for Puma specific warnings and errors
class LanguagePack::Helpers::PumaWarnError
  attr_reader :warnings, :error, :puma_version

  def initialize(puma_version:, env:)
    @warnings = []
    @error = nil
    @env = env
    @puma_version = puma_version

    warn_router_2_0_compatability
    error_persistent_timeout
  end

  private def warn_router_2_0_compatability
    return if @puma_version >= Gem::Version.new("7.0.3")
    warnings << <<~WARNING
      Heroku recommends using Puma 7.0.3+ for compatability with Router 2.0

      Please upgrade your application to Puma 7.0.3+ by running the following commands:

      ```
      $ gem install puma
      $ bundle update puma
      $ git add Gemfile.lock && git commit -m "Upgrade Puma to 7.0.3+"
      ```
    WARNING
  end

  private def error_persistent_timeout
    return if @puma_version >= Gem::Version.new("7.0.3")
    return if @puma_version < Gem::Version.new("7.0.0")
    # If they manually set it, it is likely being used in their `config/puma.rb` file
    return if @env["PUMA_PERSISTENT_TIMEOUT"]

    @error = <<~ERROR
      Your application is using Puma #{puma_version}.

      This has a known issue with the `PUMA_PERSISTENT_TIMEOUT` environment variable.

      This is fixed in Puma 7.0.3+ via https://github.com/puma/puma/pull/3749.
      Please upgrade your application to Puma 7.0.3+ by running the following commands:

      ```
      $ gem install puma
      $ bundle update puma
      $ git add Gemfile.lock && git commit -m "Upgrade Puma to 7.0.3+"
      ```
    ERROR
  end
end
