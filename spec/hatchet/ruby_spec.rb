require_relative '../spec_helper'

describe "Ruby apps" do
  # https://github.com/heroku/heroku-buildpack-ruby/issues/1025
  describe "bin/rake binstub" do
    it "loads git gems at build time when executing `rake`" do
      Hatchet::Runner.new("git_gemspec").tap do |app|
        app.before_deploy do
          File.open("Rakefile", "w+") do |f|
            f.puts(<<~EOF)
            task "assets:precompile" do
              require 'mini_histogram'
              puts "successfully loaded git gem"
            end
            EOF
          end
        end
        app.deploy do
          expect(app.output).to match("successfully loaded git gem")
          expect(app.run("rake assets:precompile")).to match("successfully loaded git gem")
        end
      end
    end

    it "loads bundler into memory" do
      Hatchet::Runner.new("default_ruby").tap do |app|
        app.before_deploy do
          File.open("Rakefile", "w+") do |f|
            f.puts(<<~EOF)
            task "assets:precompile" do
              puts Bundler.methods

              puts "bundler loaded in rake context"
            end
            EOF
          end
        end
        app.deploy do
          expect(app.output).to match("bundler loaded in rake context")
          expect(app.run("rake assets:precompile")).to match("bundler loaded in rake context")
        end
      end
    end

    it "loads custom rake binstub" do
      Hatchet::Runner.new("default_ruby").tap do |app|
        app.before_deploy do
          FileUtils.mkdir_p("bin")

          File.open("bin/rake", "w+") do |f|
            f.puts(<<~EOF)
            #!/usr/bin/env ruby

            puts "rake assets:precompile" # Needed to trigger the `rake -P` task detection
            puts "custom rake binstub called"
            EOF
          end
          FileUtils.chmod("+x", "bin/rake")
        end
        app.deploy do
          expect(app.output).to match("custom rake binstub called")
          expect(app.run("rake")).to match("custom rake binstub called")
        end
      end
    end
  end

  describe "bad ruby version" do
    it "gives a helpful error" do
      Hatchet::Runner.new('ruby_version_does_not_exist', allow_failure: true, stack: DEFAULT_STACK).deploy do |app|
        expect(app.output).to match("The Ruby version you are trying to install does not exist: ruby-2.9.0.lol")
      end
    end
  end

  describe "exporting path" do
    it "puts local bin dir in path" do
      before_deploy = Proc.new do
        FileUtils.mkdir_p("bin")
        File.open("bin/bloop", "w+") do |f|
          f.puts(<<~EOF)
          #!/usr/bin/env bash

          echo "bloop"
          EOF
        end
        FileUtils.chmod("+x", "bin/bloop")

        File.open("Rakefile", "a") do |f|
          f.puts(<<~EOF)
          task "run:bloop" do
            puts `bloop`
            raise "Could not bloop" unless $?.success?
          end
          EOF
        end
      end
      buildpacks = [
        :default,
        "https://github.com/schneems/buildpack-ruby-rake-deploy-tasks"
      ]
      config = { "DEPLOY_TASKS" => "run:bloop"}
      Hatchet::Runner.new('default_ruby', stack: DEFAULT_STACK, buildpacks: buildpacks, config: config, before_deploy: before_deploy).deploy do |app|
        expect(app.output).to match("bloop")
      end
    end
  end

  describe "running Ruby from outside the default dir" do
    it "works" do
      buildpacks = [
        :default,
        "https://github.com/sharpstone/force_absolute_paths_buildpack",
        "https://github.com/heroku/heroku-buildpack-inline.git",
      ]
      config = {FORCE_ABSOLUTE_PATHS_BUILDPACK_IGNORE_PATHS: "BUNDLE_PATH"}


      Hatchet::Runner.new('default_ruby', stack: DEFAULT_STACK, buildpacks: buildpacks, config: config).tap do |app|
        app.before_deploy do
          Pathname("Gemfile").write(<<~'EOF')
            source "https://rubygems.org"

            gem "rake"
          EOF

          Pathname("Gemfile.lock").write(<<~'EOF')
            GEM
              remote: https://rubygems.org/
              specs:
                rake (13.0.6)

            PLATFORMS
              ruby
              x86_64-darwin-20

            DEPENDENCIES
              rake

            RUBY VERSION
               ruby 3.3.1p0
          EOF

          Pathname("Rakefile").write(<<~'EOF')
            task "assets:precompile" do
              out = `cd client && bundle exec ruby -v`
              puts "cd version #{out}"
              unless $?.success?
                puts "Failed: #{out}"
                exit 1
              end
            end
          EOF

          dir = Pathname("client")
          dir.mkpath
          FileUtils.touch(dir.join(".gitkeep"))

          # Inline buildpack to ensure build_report file is emitted on compile
          bin = Pathname("bin").tap(&:mkpath)
          detect = bin.join("detect")
          compile = bin.join("compile")
          release = bin.join("release")

          [detect, compile, release].each do |path|
            FileUtils.touch(path)
            FileUtils.chmod("+x", path)
            path.write(<<~EOF)
              #!/usr/bin/env bash
              exit 0
            EOF
          end

          bash_functions_contents = Pathname(__dir__).join("..").join("..").join("bin").join("support").join("bash_functions.sh").read
          bin.join("support").tap(&:mkpath).join("bash_functions.sh").write(<<~EOF)
            #{bash_functions_contents}
          EOF

          compile.write(<<~EOF)
            #!/usr/bin/env bash

            echo "## PRINTING REPORT FILE ##"
            #{Pathname(__dir__).join("..").join("..").join("bin").join("report").read}
            echo "## REPORT FILE DONE ##"
          EOF
        end

        app.deploy do |app|
          expected = "3.3.1"
          expect(expected).to_not eq(LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER)
          expect(app.output).to match("cd version ruby #{expected}")
          begin
            report_match = app.output.match(/## PRINTING REPORT FILE ##(?<yaml>.*)## REPORT FILE DONE/m) # https://rubular.com/r/FfaV5AEstigaMO
            expect(report_match).to be_truthy
            yaml = report_match[:yaml].gsub(/remote: /, "")
            report = YAML.load(yaml)
            expect(report.fetch("ruby_version_full")).to eq(expected)
          rescue Exception => e
            puts app.output
            puts yaml if yaml
            puts report.inspect if report
            raise e
          end

          expect(app.run("which ruby").strip).to eq("/app/bin/ruby")
        end
      end
    end
  end

  describe "bundler ruby version matcher" do
    it "installs a version even when not present in the Gemfile.lock" do
      version = "3.3.1"
      expect(version).to_not eq(LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER)

      Hatchet::Runner.new('default_ruby', stack: DEFAULT_STACK).tap do |app|
        app.before_deploy do
          Pathname("Gemfile").write(<<~EOF)
            source "https://rubygems.org"

            ruby "#{version}"

            gem "sinatra"
          EOF

          Pathname("Gemfile.lock").write(<<~'EOF')
            GEM
              remote: https://rubygems.org/
              specs:
                mustermann (1.1.1)
                  ruby2_keywords (~> 0.0.1)
                rack (2.2.3)
                rack-protection (2.2.0)
                  rack
                ruby2_keywords (0.0.5)
                sinatra (2.2.0)
                  mustermann (~> 1.0)
                  rack (~> 2.2)
                  rack-protection (= 2.2.0)
                  tilt (~> 2.0)
                tilt (2.0.10)

            PLATFORMS
              ruby
              x86_64-darwin-20

            DEPENDENCIES
              sinatra
          EOF

        end

        app.deploy do |app|
          expect(app.output).to_not include("unbound variable")

          # Intentionally different than the default ruby version
          expect(app.output).to         match("#{version}")
          expect(app.run("ruby -v")).to match("#{version}")
        end
      end
    end
  end

  describe "database configuration" do
    context "no active record" do
      it "writes a heroku specific database.yml" do
        Hatchet::Runner.new("default_ruby").deploy do |app, heroku|
          expect(app.output).to     include("Writing config/database.yml to read from DATABASE_URL")
          expect(app.output).not_to include("Your app was upgraded to bundler")
          expect(app.output).not_to include("Your Ruby version is not present on the next stack")
        end
      end
    end

    context "active record 4.1+" do
      it "doesn't write a heroku specific database.yml" do
        Hatchet::Runner.new("rails61", config: rails_lts_config, stack: rails_lts_stack).tap do |app|
          app.deploy do
            expect(app.output).not_to include("Writing config/database.yml to read from DATABASE_URL")
          end
        end
      end
    end
  end
end

describe "Raise errors on specific gems" do
  it "should raise on sqlite3" do
    Hatchet::Runner.new("sqlite3_gemfile", allow_failure: true).deploy do |app|
      expect(app).not_to be_deployed
      expect(app.output).to include("Detected sqlite3 gem which is not supported")
      expect(app.output).to include("devcenter.heroku.com/articles/sqlite3")
    end
  end
end

describe "No Lockfile" do
  it "should not deploy" do
    Hatchet::Runner.new("no_lockfile", allow_failure: true).deploy do |app|
      expect(app).not_to be_deployed
      expect(app.output).to include("Gemfile.lock required")
    end
  end
end

describe "Rack" do
  it "should not overwrite already set environment variables" do
    custom_env = SecureRandom.hex(16)
    app = Hatchet::Runner.new("default_ruby", config: {"RACK_ENV" => custom_env, "BUNDLE_SIMULATE_VERSION" => "4" })
    app.before_deploy do
      Pathname("Rakefile").write(<<~'EOF')
        task "assets:precompile" do
          puts "Build time RACK_ENV: #{ENV["RACK_ENV"]}"
        end
      EOF

      set_bundler_version(version: "2.7.2")
    end

    app.deploy do |app|
      # Assert build time user provided value takes precedence over default
      expect(app.output).to match("Build time RACK_ENV: #{custom_env}")

      # Assert runtime/launch user provided value takes precedence over default
      environment_variables = app.run("env")
      expect(environment_variables).to match("RACK_ENV=#{custom_env}")
      expect(environment_variables).to match("PUMA_PERSISTENT_TIMEOUT")

      profile_d = app.run("cat .profile.d/ruby.sh")
        .strip
        .split("\n")
        .sort
        .join("\n")

      expect(profile_d).to eq(<<~EOF.strip)
       export BUNDLE_BIN=${BUNDLE_BIN:-vendor/bundle/bin}
       export BUNDLE_DEPLOYMENT=${BUNDLE_DEPLOYMENT:-1}
       export BUNDLE_PATH=${BUNDLE_PATH:-vendor/bundle}
       export BUNDLE_WITHOUT=${BUNDLE_WITHOUT:-development:test}
       export DISABLE_SPRING="1"
       export GEM_PATH="$HOME/vendor/bundle/ruby/3.3.0:$GEM_PATH"
       export LANG=${LANG:-en_US.UTF-8}
       export MALLOC_ARENA_MAX=${MALLOC_ARENA_MAX:-2}
       export PATH="$HOME/bin:$HOME/vendor/bundle/bin:$HOME/vendor/bundle/ruby/3.3.0/bin:$PATH"
       export PUMA_PERSISTENT_TIMEOUT=${PUMA_PERSISTENT_TIMEOUT:-95}
       export RACK_ENV=${RACK_ENV:-production}
      EOF
    end
  end
end

describe "build time config var behavior" do
  class EnvDiff
    attr_reader :added, :modified, :path_before, :path_after

    def initialize(output)
      build_dir = output.match(/BUILD_DIR: (.+)/)&.[](1)&.strip
      if build_dir
        output.gsub!(build_dir, '<build dir>')
      else
        raise "BUILD_DIR not found in output:\n#{output}"
      end

      env_sections = extract_env_sections(output)
      raise "Too many print markers in output found:\n#{output}" if env_sections.size > 2

      before_hash = env_sections[0] or raise "Did not find any print markers in output:\n#{output}"
      after_hash = env_sections[1] or raise "Did not find second set of print markers in output:\n#{output}"

      @path_before = before_hash["PATH"]
      @path_after = after_hash["PATH"]

      non_path_before = before_hash.except("PATH")
      non_path_after = after_hash.except("PATH")

      @added = (non_path_after.keys - non_path_before.keys).sort.map { |k| "#{k}=#{non_path_after[k]}" }
    end

    private def extract_env_sections(output, start_marker: "## PRINTING ENV ##", end_marker: "## PRINTING ENV DONE ##")
      sections = []
      in_section = false
      current_env = {}

      output.each_line do |line|
        clean = line.gsub(/^\s*remote:\s*/, '').strip
        case clean
        when start_marker
          in_section = true
          current_env = {}
        when end_marker
          sections << current_env
          in_section = false
        else
          if in_section && clean.include?('=')
            key, value = clean.split('=', 2)
            current_env[key] = value
          end
        end
      end
      sections
    end
  end

  it "works" do
    # Print out the `env` of the build process before and after the Ruby buildpack and diff the results
    buildpacks = [
      "https://github.com/heroku/heroku-buildpack-inline.git",
      :default,
      "https://github.com/heroku/heroku-buildpack-inline.git",
    ]

    Hatchet::Runner.new('default_ruby', stack: DEFAULT_STACK, buildpacks: buildpacks).tap do |app|
      app.before_deploy do
        bin = Pathname("bin").tap(&:mkpath)
        detect = bin.join("detect")
        compile = bin.join("compile")
        release = bin.join("release")

        [detect, compile, release].each do |path|
          FileUtils.touch(path)
          FileUtils.chmod("+x", path)
          path.write(<<~EOF)
            #!/usr/bin/env bash
            exit 0
          EOF
        end

        compile.write(<<~EOF)
          #!/usr/bin/env bash
          set -euo pipefail

          BUILD_DIR=$1
          echo "BUILD_DIR: $BUILD_DIR"

          echo "## PRINTING ENV ##"
          env | sort
          echo "## PRINTING ENV DONE ##"
          exit 0
        EOF
      end

      app.deploy do
        diff = EnvDiff.new(app.output)

        expect(diff.added.join("\n")).to eq(<<~EOF.strip)
          BUNDLE_BIN=vendor/bundle/bin
          BUNDLE_DEPLOYMENT=1
          BUNDLE_PATH=vendor/bundle
          BUNDLE_WITHOUT=development:test
          GEM_PATH=<build dir>/vendor/bundle/ruby/3.3.0:
          PUMA_PERSISTENT_TIMEOUT=95
          RACK_ENV=production
        EOF

        expect(diff.path_after).to include(diff.path_before)
        expect(diff.path_after).to include("<build dir>/bin:<build dir>/vendor/bundle/bin:<build dir>/vendor/bundle/ruby/3.3.0/bin:<build dir>/vendor/ruby-3.3.9/bin")
      end
    end
  end
end

describe "WEB_CONCURRENCY.sh" do
  it "from a preceding buildpack is overwritten by this buildpack" do
    buildpacks = [
      "heroku/nodejs",
      :default
    ]
    before_deploy = -> { run!(%Q{echo "{}" > package.json}) }
    Hatchet::Runner.new('default_ruby', stack: DEFAULT_STACK, buildpacks: buildpacks, before_deploy: before_deploy).deploy do |app|
      expect(app.run("cat .profile.d/WEB_CONCURRENCY.sh").strip).to be_empty
      expect(app.run("echo $WEB_CONCURRENCY").strip).to be_empty
      expect(app.run("echo $WEB_CONCURRENCY", :heroku => {:env => "WEB_CONCURRENCY=0"}).strip).to eq("0")
    end
  end
end
