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
end
