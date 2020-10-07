# frozen_string_literal: true

require 'language_pack/helpers/binstub_wrapper'
# This class is designed to check for binstubs for validity
#
# Example:
#
#   check = LanguagePack::Helpers::BinstubCheck.new(app_root_dir: Dir.pwd, warn_object: self)
#   check.call
class LanguagePack::Helpers::BinstubCheck
  attr_reader :bad_binstubs

  def initialize(app_root_dir:, warn_object: )
    @bin_dir = Pathname.new(app_root_dir).join("bin")
    @warn_object = warn_object
    @bad_binstubs = []
  end

  # Checks all binstubs in the directory for a
  # bad shebang line. If any are present
  # a warning is created on the passed in `warn_object`
  def call
    return unless @bin_dir.directory?

    each_binstub do |binstub|
      @bad_binstubs << binstub if binstub.bad_shebang?
    end

    warn unless @bad_binstubs.empty?
  end

  # Iterates and yields each binstub in a directory
  # as a BinstubWrapper
  private def each_binstub
    @bin_dir.entries.each do |basename|
      binstub = LanguagePack::Helpers::BinstubWrapper.new(@bin_dir.join(basename))

      next unless binstub.file? # Needed since "." and ".." are returned by Pathname#entries
      yield binstub
    end
  end

  private def warn
    message = <<~EOM
      Improperly formatted binstubs detected in your project

      The following file(s) have appear to contain a problematic "shebang" line

      #{@bad_binstubs.map {|binstub| "  - bin/#{binstub.basename}" }.join("\n")}

      For example bin/#{@bad_binstubs.first.basename} has the shebang line:

      ```
      #{@bad_binstubs.first.open(&:readline).strip}
      ```

      It should be:

      ```
      #!/usr/bin/env ruby
      ```

      A malformed shebang line may cause your program to crash.

      For more information about binstubs and "shebang" lines see:
        https://devcenter.heroku.com/articles/bad-ruby-binstub-shebang
    EOM

    @warn_object.warn(message, inline: true)
  end
end
