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

  describe "mcount" do
    it "logs to a file" do
      begin
        original = ENV["BUILDPACK_LOG_FILE"]
        Tempfile.open("logfile.log") do |f|
          ENV["BUILDPACK_LOG_FILE"] = f.path
          FakeShell.new.mcount "foo"
          expect(File.read(f.path)).to match("count#buildpack.ruby.foo=1")
        end
      ensure
        ENV["BUILDPACK_LOG_FILE"] = original
      end
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
      it 'no error is raised' do
        sh = FakeShell.new

        bad_lines = File.read("spec/fixtures/invalid_encoding.log")
        sh.puts(bad_lines)
      end

      it 'catches it just in case' do
        sh = FakeShell.new

        def sh.print(string); string.strip; end
        def sh.mcount(*args); @error_caught = true; end

        bad_lines = File.read("spec/fixtures/invalid_encoding.log")
        expect { sh.puts(bad_lines) }.to raise_error(ArgumentError)

        error_caught = sh.instance_variable_get(:"@error_caught")
        expect(error_caught).to eq(true)
      end
    end
  end
end
