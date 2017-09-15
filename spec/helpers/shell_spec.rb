require 'spec_helper'

describe "ShellHelpers" do
  module RecordPuts
    attr_reader :puts_calls
    def puts(*args)
      @puts_calls ||= []
      @puts_calls << args
    end
  end

  class FakeShell
    include RecordPuts
    include LanguagePack::ShellHelpers
  end

  describe "#command_options_to_string" do
    it "formats ugly keys correctly" do
      env      = {%Q{ un"matched } => "bad key"}
      result   = FakeShell.new.command_options_to_string("bundle install", env:  env)
      expected = %r{env \\ un\\\"matched\\ =bad\\ key bash -c bundle\\ install 2>&1}
      expect(result.strip).to match(expected)
    end

    it "formats ugly values correctly" do
      env      = {"BAD VALUE"      => %Q{ )(*&^%$#'$'\n''@!~\'\ }}
      result   = FakeShell.new.command_options_to_string("bundle install", env:  env)
      expected = %r{env BAD\\ VALUE=\\ \\\)\\\(\\\*\\&\\\^\\%\\\$\\#\\'\\\$\\''\n'\\'\\'@\\!\\~\\'\\  bash -c bundle\\ install 2>&1}
      expect(result.strip).to match(expected)
    end
  end

  describe "#run!" do
    it "retries failed commands when passed max_attempts: > 1" do
      sh = FakeShell.new
      expect { sh.run!("false", max_attempts: 3) }.to raise_error(StandardError)

      expect(sh.puts_calls).to eq([
        ["       Command: 'false' failed on attempt 1 of 3."],
        ["       Command: 'false' failed on attempt 2 of 3."],
      ])
    end
  end
end
