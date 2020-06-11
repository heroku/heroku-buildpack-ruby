# frozen_string_literal: true

# This class is designed to check for binstubs for validity
#
# Example:
#
#   check = LanguagePack::Helpers::BinstubCheck.new(Dir.pwd, self)
#   check.call
class LanguagePack::Helpers::BinstubCheck
  attr_reader :bad_binstubs

  def initialize(app_root_dir:, warn_object: )
    @bin_dir = Pathname.new(app_root_dir).join("bin")
    @warn_object = warn_object
    @bad_binstubs = []
  end

  def call
    return unless @bin_dir.directory?

    @bin_dir.entries.each do |basename|
      binstub = @bin_dir.join(basename)
      next unless binstub.file?

      shebang = binstub.open(&:readline)

      if shebang.match?(/^#!\s*\/usr\/bin\/env\s*ruby(\d.*)$/) # https://rubular.com/r/ozbNEPVInc3sSN
        @bad_binstubs << binstub
      end
      rescue EOFError
    end

    warn unless @bad_binstubs.empty?
  end

  private def warn
    message = <<~EOM
      Improperly formatted binstubs detected in your project

      The following file(s) have appear to contain a problematic "shebang" line

      #{@bad_binstubs.map {|binstub| "  - bin/#{binstub.basename}" }.join("\n")}

      For example bin/#{@bad_binstubs.first.basename} has the shebang line:

      ```
      #{@bad_binstubs.first.open(&:readline).chomp}
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
