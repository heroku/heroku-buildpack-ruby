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

      expect(sh.puts_calls).to eq([
        ["       Command: 'false' failed on attempt 1 of 3."],
        ["       Command: 'false' failed on attempt 2 of 3."],
      ])
    end
  end

  def read_file_lines
    lines = []
    File.open("spec/fixtures/invalid_encoding.log") do |f|
      f.each_line do |line|
        lines << line
      end
    end
    lines
  end

  describe "#puts" do

    context 'when the message has valid encoding' do
      it 'does not raise an exception' do
        sh = FakeShell.new
        expect(Kernel).to_not receive(:puts)
        message = "npm WARN optional SKIPPING OPTIONAL DEPENDENCY: fsevents@^1.0.0 (node_modules/chokidar/node_modules/fsevents)"
        result = sh.puts message
        expect(result).to eq $stdout.flush
      end
    end

    context 'when the message does not have a valid utf-8 character' do
      it 'rescues the error and show the message as string' do
        sh = FakeShell.new
        lines = read_file_lines
        expect(Kernel).to receive(:puts)
        result = sh.puts lines[0]
        expect(result).to eq $stdout.flush
      end
    end
  end
end
