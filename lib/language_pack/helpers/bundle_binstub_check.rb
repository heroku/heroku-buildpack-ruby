# frozen_string_literal: true

# Checks for the presence of a `bin/bundle` binstub in the app.
#
# When `bin/bundle` exists, bundler may remove itself during `bundle clean`
# and then fall back to the default bundler version shipped with Ruby at
# runtime, which can be a different major version than what the app expects.
#
# The fix is to remove the `bin/bundle` binstub from the app.
#
# See: https://github.com/heroku/heroku-buildpack-ruby/issues/1690
# See: https://github.com/ruby/rubygems/issues/9218
#
# Example:
#
#   check = LanguagePack::Helpers::BundleBinstubCheck.new(
#     app_root_dir: Dir.pwd,
#     warn_object: self
#   )
#   check.call
#
class LanguagePack::Helpers::BundleBinstubCheck
  def initialize(app_root_dir:, warn_object:)
    @bin_bundle = Pathname.new(app_root_dir).join("bin", "bundle")
    @warn_object = warn_object
  end

  def call
    return false unless @bin_bundle.exist?

    @warn_object.warn(warning_message, inline: true)
    true
  end

  private

  def warning_message
    <<~WARNING
      Your app has a `bin/bundle` binstub that may cause bundler to
      malfunction. We recommend you remove it.

      When `bin/bundle` is present, `bundle clean` may remove the
      installed version of bundler and then your app falls back to
      the default bundler version that ships with Ruby, which can be
      a different major version than expected.

      To fix this issue, run:

      ```
      $ rm bin/bundle
      $ git add .
      $ git commit -m "Remove bin/bundle binstub"
      ```

      For more information see:
        https://github.com/heroku/heroku-buildpack-ruby/issues/1690
    WARNING
  end
end
