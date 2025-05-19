require 'spec_helper'

describe "ShellHelpers" do
  module RecordPuts
    attr_reader :puts_calls, :print_calls
    def puts(*args)
      @puts_calls ||= []
      @puts_calls << args
    end

    def print(*args)
      @print_calls ||= []
      @print_calls << args
    end
  end

  class FakeShell
    include RecordPuts
    include LanguagePack::ShellHelpers
  end

  describe "pipe" do
    it "does not double append newlines" do
      sh = FakeShell.new
      sh.pipe('bundle install')
      first_line = sh.print_calls.first.first
      expect(first_line.end_with?("\n\n")).to be(false)
    end
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

      expect(sh.print_calls).to eq([
        ["       Command: 'false' failed on attempt 1 of 3.\n"],
        ["       Command: 'false' failed on attempt 2 of 3.\n"],
      ])
    end
  end

  describe "#puts" do
    context 'when the message has an invalid utf-8 character' do
      it 'no error is raised by puts directly' do
        sh = FakeShell.new

        bad_lines = File.read("spec/fixtures/invalid_encoding.log")
        sh.puts(bad_lines)
      end

      it 'from an internal call, it catches and annotates it' do
        sh = FakeShell.new

        def sh.print(string)
          # Strip emits a UTF-8 error
          string.strip
        end

        bad_lines = File.read("spec/fixtures/invalid_encoding.log")
        expect { sh.puts(bad_lines) }.to raise_error do |error|
          expect(error.message).to include("Invalid string:")
        end
      end
    end
  end
end
