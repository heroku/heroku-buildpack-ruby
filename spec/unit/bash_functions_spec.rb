require 'spec_helper'

describe "Bash functions" do
    it "Detects jruby in the Gemfile.lock" do
      Dir.mktmpdir do |dir|
        dir = Pathname(dir)
        dir.join("Gemfile.lock").write <<~EOM
          RUBY VERSION
             ruby 2.5.7p001 (jruby 9.2.13.0)
        EOM


        out = exec_with_bash_functions <<~EOM
          which_java()
          {
            return 1
          }

          if detect_needs_java "#{dir}"; then
            echo "jruby detected"
          else
            echo "nope"
          fi
        EOM

        expect(out).to eq("jruby detected")

        dir.join("Gemfile.lock").write <<~EOM
        EOM

        out = exec_with_bash_functions <<~EOM
          which_java()
          {
            return 1
          }

          if detect_needs_java "#{dir}"; then
            echo "jruby detected"
          else
            echo "nope"
          fi
        EOM

        expect(out).to eq("nope")
      end
    end

    it "Detects java for jruby detection" do
      Dir.mktmpdir do |dir|
        dir = Pathname(dir)
        dir.join("Gemfile.lock").write <<~EOM
          RUBY VERSION
             ruby 2.5.7p001 (jruby 9.2.13.0)
        EOM

        out = exec_with_bash_functions <<~EOM
          which_java()
          {
            return 0
          }

          if detect_needs_java "#{dir}"; then
            echo "jruby detected"
          else
            echo "already installed"
          fi
        EOM

        expect(out).to eq("already installed")
      end
    end


  def bash_functions_file
    root_dir.join("bin", "support", "bash_functions.sh")
  end

  def exec_with_bash_functions(code, stack: "heroku-18")
    contents = <<~EOM
      #! /usr/bin/env bash
      set -eu

      STACK="#{stack}"

      #{bash_functions_file.read}

      #{code}
    EOM

    file = Tempfile.new
    file.write(contents)
    file.close
    FileUtils.chmod("+x", file.path)

    out = nil
    success = false
    begin
      Timeout.timeout(60) do
        out = `#{file.path} 2>&1`.strip
        success = $?.success?
      end
    rescue Timeout::Error
      out = "Command timed out"
      success = false
    end
    unless success
      message = <<~EOM
        Contents:

        #{contents.lines.map.with_index { |line, number| "  #{number.next} #{line.chomp}"}.join("\n") }

        Expected running script to succeed, but it did not

        Output:

          #{out}
      EOM

      raise message
    end
    out
  end
end
