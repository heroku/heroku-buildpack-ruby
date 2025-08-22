require 'spec_helper'

describe "Bash functions" do
    describe "metrics" do
      it "prints error when missing report env var" do
        out = exec_with_bash_file(code: <<~EOM, file: bash_functions_file, strip_output: false)
          unset HEROKU_RUBY_BUILD_REPORT_FILE
          metrics::print
        EOM

        expect(out).to eq(<<~EOM)
          {
            "report_file_path": "(unset)",
            "report_file_missing": true
          }
        EOM
      end

      it "prints error when report env var is set to a non-existent file" do
        Dir.mktmpdir do |dir|
          file = Pathname(dir).join("does-not-exist").expand_path
          out = exec_with_bash_file(code: <<~EOM, file: bash_functions_file, strip_output: false)
            export HEROKU_RUBY_BUILD_REPORT_FILE="#{file}"
            build_data::print
          EOM

          expect(out).to eq(<<~EOM)
            {
              "report_file_path": "#{file}",
              "report_file_missing": true
            }
          EOM
        end
      end

      it "kv_duration_since" do
        out = exec_with_bash_file(code: <<~EOM, file: bash_functions_file, strip_output: false)
          build_data::init "$(mktemp -d)"
          build_data::clear

          timer=$(build_data::current_unix_realtime)
          sleep 0.1
          build_data::kv_duration_since "ruby_install_ms" "${timer}"
          build_data::print
        EOM

        begin
          ruby_install_s = JSON.parse(out).fetch("ruby_install_ms").to_f
          expect(ruby_install_s).to be_between(0.1, 1)
        rescue
          puts "Output: #{out}"
          raise
        end
      end

      it "kv_string" do
        out = exec_with_bash_file(code: <<~EOM, file: bash_functions_file, strip_output: false)
          build_data::init "$(mktemp -d)"
          build_data::clear

          build_data::kv_string "ruby_version" "3.3.0"
          build_data::print
        EOM

        expect(out).to eq(<<~EOM)
          {
            "ruby_version": "3.3.0"
          }
        EOM
      end

      it "kv_string" do
        out = exec_with_bash_file(code: <<~EOM, file: bash_functions_file, strip_output: false)
          build_data::init "$(mktemp -d)"
          build_data::clear

          build_data::kv_string "ruby_version" "3.3.0"
          build_data::print
        EOM

        expect(out).to eq(<<~EOM)
          {
            "ruby_version": "3.3.0"
          }
       EOM
      end

      it "kv_raw" do
        out = exec_with_bash_file(code: <<~EOM, file: bash_functions_file, strip_output: false)
          build_data::init "$(mktemp -d)"
          build_data::clear

          build_data::kv_raw "ruby_minor" "3"
          build_data::print
        EOM

        expect(out).to eq(<<~EOM)
          {
            "ruby_minor": 3
          }
        EOM
      end
    end

    it "fails on old stacks" do
      out = exec_with_bash_functions(<<~EOM, raise_on_fail: false)
        build_data::init "$(mktemp -d)"
        build_data::clear

        checks::ensure_supported_stack "heroku-20"
      EOM

      expect($?.success?).to be_falsey, "Expected command failure but got unexpected success. Output:\n\n#{out}"
      expect(out).to include("This buildpack no longer supports the 'heroku-20' stack")
    end

    it "knows the latest stacks" do
      out = exec_with_bash_functions(<<~EOM)
        checks::ensure_supported_stack "heroku-24"
      EOM

      expect(out).to be_empty
    end

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
          build_data::init "$(mktemp -d)"
          build_data::clear

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

  def exec_with_bash_file(file:, code:, stack: "heroku-24", raise_on_fail: true, strip_output: true)
    contents = <<~EOM
      #! /usr/bin/env bash
      set -eu

      STACK="#{stack}"

      #{file.read}

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
        out = `#{file.path} 2>&1`
        out = out.strip if strip_output
        success = $?.success?
      end
    rescue Timeout::Error
      out = "Command timed out"
      success = false
    end

    if raise_on_fail && !success
      message = <<~EOM
        Contents:

        #{contents.lines.map.with_index { |line, number| "  #{number.next} #{line.chomp}"}.join("\n") }

        Expected running script to succeed, but it did not. If this was expected, use `raise_on_fail: false`

        Output:

          #{out}
      EOM

      raise message
    else
      out
    end
  end

  def exec_with_bash_functions(code, stack: "heroku-24", raise_on_fail: true)
    exec_with_bash_file(
      code: code,
      file: bash_functions_file,
      stack: stack,
      raise_on_fail: raise_on_fail
    )
  end
end
