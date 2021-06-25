# frozen_string_literal: true

class LanguagePack::Helpers::RailsBootcheck
  include LanguagePack::ShellHelpers

  def initialize(timeout = 65)
    @timeout = timeout
  end

  def call
    return unless opted_in? && !opted_out?

    topic("Bootchecking rails application")

    process = ProcessSpawn.new(
      "rails runner 'puts Rails.env'",
      user_env: true,
      timeout:  @timeout,
      file:     "./.heroku/ruby/compile/rails_bootcheck.txt"
    )

    if process.timeout?
      failure("timeout", process.output)
    elsif !process.success?
      failure("failure", process.output)
    end
  end

  private

  def failure(type, output)
    message = String.new("Bootchecking rails application #{type}\n")
    message << "set HEROKU_RAILS_BOOTCHECK_DISABLE=1 to disable this feature\n"

    if !output.empty?
      message << "\n"
      message << output
    end

    error(message)
  end

  def opted_in?
    env("HEROKU_RAILS_BOOTCHECK_ENABLE")
  end

  def opted_out?
    env("HEROKU_RAILS_BOOTCHECK_DISABLE")
  end
end
