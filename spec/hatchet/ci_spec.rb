require 'spec_helper'

describe "CI" do
  it "Does not cause the double ruby rainbow bug" do
    Hatchet::Runner.new("heroku-ci-json-example").run_ci do |test_run|
      expect(test_run.status).to eq(:succeeded)

      install_bundler_count = test_run.output.scan("Installing bundler").count
      expect(install_bundler_count).to eq(1), "Expected output to only install bundler once but was found #{install_bundler_count} times. output:\n#{test_run.output}"
    end
  end

  it "Works with Rails: ruby schema apps" do
    Hatchet::Runner.new("rails_8_ruby_schema", stack: "heroku-24").tap do |app|
      app.before_deploy do
        Pathname("app.json").write(<<~EOF)
          {
            "environments": {
              "test": {
                "addons":[
                  "heroku-postgresql:in-dyno"
                ]
              }
            }
          }
        EOF
      end

      app.run_ci do |test_run|
        expect(test_run.output).to match("db:schema:load completed")
      end
    end
  end

  it "Works with Rails: SQL schema apps" do
    Hatchet::Runner.new("rails_8_sql_schema", stack: "heroku-24").tap do |app|
      app.before_deploy do
        Pathname("app.json").write(<<~EOF)
          {
            "environments": {
              "test": {
                "addons":[
                  "heroku-postgresql:in-dyno"
                ]
              }
            }
          }
        EOF
      end

      app.run_ci do |test_run|
        expect(test_run.output).to match("db:schema:load completed")
      end
    end
  end

  it "Works with a vanilla ruby app" do
    Hatchet::Runner.new("ruby_no_rails_test").run_ci do |test_run|
      # Test no whitespace in front of output
      expect(test_run.output).to_not match(/^ +Finished in/)
      expect(test_run.output).to     match(/^Finished in/)
    end
  end

  it "Uses the cache" do
    runner = Hatchet::Runner.new("ruby_no_rails_test")
    runner.run_ci do |test_run|
      fetching_rake = "Fetching rake"
      expect(test_run.output).to match(fetching_rake)

      test_run.run_again

      expect(test_run.output).to_not match(fetching_rake)
    end
  end

  it "CI build time config var behavior" do
    script = "echo '## PRINTING ENV ##' && env | sort && echo '## PRINTING ENV DONE ##'; echo '## PRINTING BIN ## ' && ls -1 ./bin | sort && echo '## PRINTING BIN DONE ##'"

    # First, capture env BEFORE the Ruby buildpack runs using an inline buildpack
    before_output = nil
    Hatchet::Runner.new("default_ruby", stack: DEFAULT_STACK, buildpacks: ["https://github.com/heroku/heroku-buildpack-inline.git"]).tap do |app|
      app.before_deploy do
        bin = Pathname("bin").tap(&:mkpath)
        %w[detect compile release].each do |name|
          path = bin.join(name)
          FileUtils.touch(path)
          FileUtils.chmod("+x", path)
          path.write("#!/usr/bin/env bash\nexit 0\n")
        end

        Pathname("app.json").write(<<~EOF)
          {
            "environments": {
              "test": {
                "scripts": {
                  "test": "#{script}"
                }
              }
            }
          }
        EOF
      end

      app.run_ci do |test_run|
        before_output = test_run.output
      end
    end

    # Test `bin/test` auto executing code, which is a slightly different path than if they define a test task in the `app.json`
    Hatchet::Runner.new("default_ruby", stack: DEFAULT_STACK).tap do |app|
      app.before_deploy do
        bin_rake = Pathname("bin").tap(&:mkpath).join("rake")
        bin_rake.write(<<~EOF)
          #!/usr/bin/env bash

          # Only print markers when running the test task, not for other rake invocations
          # like `rake -v` which the buildpack uses to detect rake tasks
          if [[ "$1" == "test" ]]; then
            #{script}
          else
            # Remove this script's directory from PATH to find the real rake
            SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
            PATH="${PATH//$SCRIPT_DIR:/}" exec rake "$@"
          fi
        EOF
        FileUtils.chmod("+x", bin_rake)

        Pathname("Rakefile").write("") # triggers `rake test`
      end

      app.run_ci do |test_run|
        combined_output = before_output + "\n" + test_run.output
        diff = EnvDiff.new(combined_output, build_dir_pattern: nil)

        expect(diff.added.join("\n")).to eq(<<~EOF.strip)
          BUNDLE_BIN=vendor/bundle/bin
          BUNDLE_DEPLOYMENT=1
          BUNDLE_PATH=vendor/bundle
          BUNDLE_WITHOUT=development
          DISABLE_SPRING=1
          GEM_PATH=/app/vendor/bundle/ruby/3.3.0:
          LANG=en_US.UTF-8
          MALLOC_ARENA_MAX=2
          PUMA_PERSISTENT_TIMEOUT=95
          RACK_ENV=test
        EOF

        expect(diff.path_after).to include(diff.path_before)
        expect(diff.path_after).to start_with(
          [
            "/app/bin",
            "/app/vendor/bundle/bin",
            "/app/vendor/bundle/ruby/3.3.0/bin"
          ].join(":")
        )

        expect(extract_remote_lines(test_run.output, start_marker: "## PRINTING BIN ##", end_marker: "## PRINTING BIN DONE ##"))
          .to eq([
            "rake", # `bin/rake` is explicitly added in this test
            "erb", "gem", "irb", "racc", "rbs", "rdbg", "rdoc", "ri", "ruby", "ruby.exe", "syntax_suggest", "typeprof"
          ].sort)
      end
    end
  end

  it "works" do
    Hatchet::Runner.new("default_ruby", stack: DEFAULT_STACK).tap do |app|
      app.before_deploy do
        Pathname("Gemfile").write(<<~EOF)
          source 'http://rubygems.org'
          ruby '3.1.3'
          gem 'sinatra'
          gem 'puma'
          gem 'rack'
          gem 'rake'
          gem 'rackup'

          group :test do
            gem 'rack-test'
            gem 'test-unit'
          end
        EOF

        Pathname("Gemfile.lock").write(<<~EOF)
          GEM
            remote: http://rubygems.org/
            specs:
              base64 (0.3.0)
              logger (1.7.0)
              mustermann (3.0.4)
                ruby2_keywords (~> 0.0.1)
              nio4r (2.7.4)
              power_assert (3.0.1)
              puma (7.1.0)
                nio4r (~> 2.0)
              rack (3.2.4)
              rack-protection (4.2.1)
                base64 (>= 0.1.0)
                logger (>= 1.6.0)
                rack (>= 3.0.0, < 4)
              rack-session (2.1.1)
                base64 (>= 0.1.0)
                rack (>= 3.0.0)
              rack-test (2.2.0)
                rack (>= 1.3)
              rackup (2.3.1)
                rack (>= 3)
              rake (13.3.1)
              ruby2_keywords (0.0.5)
              sinatra (4.2.1)
                logger (>= 1.6.0)
                mustermann (~> 3.0)
                rack (>= 3.0.0, < 4)
                rack-protection (= 4.2.1)
                rack-session (>= 2.0.0, < 3)
                tilt (~> 2.0)
              test-unit (3.7.3)
                power_assert
              tilt (2.6.1)

          PLATFORMS
            ruby

          DEPENDENCIES
            puma
            rack
            rack-test
            rackup
            rake
            sinatra
            test-unit

          RUBY VERSION
             ruby 3.1.3p185

          BUNDLED WITH
             2.3.26

        EOF

        Pathname("Rakefile").write(<<~EOF)
          require 'bundler/setup'
          require 'rake/testtask'

          Rake::TestTask.new
        EOF
      end

      app.run_ci do |test_run|
        expect(test_run.output).to match("Fetching rake")
      end
    end
  end
end
