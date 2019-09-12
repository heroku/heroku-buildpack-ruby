require 'spec_helper'

describe "CI" do
  it "Does not cause the double ruby rainbow bug" do
    Hatchet::Runner.new("heroku-ci-json-example").run_ci do |test_run|
      expect(test_run.status).to eq(:succeeded)
    end
  end

  it "Works with Rails 5 ruby schema apps" do
    Hatchet::Runner.new("rails5_ruby_schema_format").run_ci do |test_run|
      expect(test_run.output).to match("db:schema:load_if_ruby completed")
    end
  end

  it "Works with Rails 5 SQL schema apps" do
    Hatchet::Runner.new("rails5_sql_schema_format").run_ci do |test_run|
      expect(test_run.output).to match("db:structure:load_if_sql completed")
    end
  end

  it "Works with Rails 3.1 ruby schema apps" do
    Hatchet::Runner.new("rails_31_ruby_schema_format").run_ci do |test_run|
      expect(test_run.output).to match("db:schema:load completed")
    end
  end

  it "Works with a vanilla ruby app" do
    Hatchet::Runner.new("ruby_no_rails_test").run_ci do |test_run|
      # Test no whitespace in front of output
      expect(test_run.output).to_not match(/^ +Finished in/)
      expect(test_run.output).to     match(/^Finished in/)
    end
  end

  it "Works with a rails app that does not have activerecord" do
    Hatchet::Runner.new("activerecord_rake_tasks_does_not_exist").run_ci do |test_run|
      expect(test_run.output).to_not match("db:migrate")
    end
  end
end
