# frozen_string_literal: true
#
# This is a helper class, it wraps a pathname object
# and adds helper methods used to pull out the first line of the file ("the shebang")
# as well as determining if the file is binary or not.
#
#   binstub = BinstubWrapper.new(Pathname.new(Dir.pwd).join("bin/rails"))
#   binstub.file? # => true
#   binstub.binary? #=> false
#   binstub.bad_shebang? #=> false
class LanguagePack::Helpers::BinstubWrapper < SimpleDelegator
  def initialize(string_or_pathname)
    @binstub = Pathname.new(string_or_pathname)
    super @binstub
  end

  # Returns false if the shebang line has a ruby binary
  # that is not simply "ruby" or "ruby.exe"
  #
  # Example:
  #
  #   bin_dir = Pathname.new(Dir.pwd).join("bin")
  #   binstub = BinstubWrapper.new(bin_dir.join("rails_good"))
  #   binstub.shebang # => "#!/usr/bin/env ruby\n"
  #   binstub.bad_shebang? # => false
  #
  #   binstub = BinstubWrapper.new(bin_dir.join("rails_bad"))
  #   binstub.shebang # => "#!/usr/bin/env ruby2.5\n"
  #   binstub.bad_shebang? # => true
  def bad_shebang?
    return false if binary?

    shebang.match?(/^#!\s*\/usr\/bin\/env\s*ruby(\d.*)$/) # https://rubular.com/r/ozbNEPVInc3sSN
  end

  # The first line of a binstub contains the "shebang" line
  # that tells the operating system how to execute the file
  # for example:
  #
  #   binstub = BinstubWrapper.new(Pathname.new(Dir.pwd).join("bin/rails"))
  #   binstub.shebang # => "#!/usr/bin/env ruby\n"
  def shebang
    @shebang ||= begin
      @binstub.open(&:readline)
    rescue EOFError
      String.new("")
    end
  end

  # Binary files (may) not have valid UTF-8 encoding. In order to
  # compare a shebang line, we must first check if the shebang
  # line is binary or not. To do that, we can see if it is not valid
  # UTF-8
  def binary?
    !valid_utf8?
  end

  def valid_utf8?
    shebang.force_encoding("UTF-8").valid_encoding?
  end
end
