require_relative '../spec_helper'

describe "Rails 4.x" do
  it "should be able to run a migration without heroku specific database.yml" do
    skip("Need RAILS_LTS_CREDS env var set") unless ENV["RAILS_LTS_CREDS"]

    Hatchet::Runner.new("rails42_default_ruby", config: rails_lts_config).tap do |app|
      app.before_deploy do
        Pathname("Gemfile").write("ruby '2.7.2'", mode: "a")
      end
      app.deploy do
        # it Don't over-write database.yml
        expect(app.output).not_to include("Writing config/database.yml to read from DATABASE_URL")

        # it sets RAILS_SERVE_STATIC_FILES env var
        output = app.run("rails runner 'puts ENV[%Q{RAILS_SERVE_STATIC_FILES}].present?'")
        expect(output).to match(/true/)
      end
    end
  end

  it "should skip asset compilation when deployed with NEW manifest file" do
    skip("Need RAILS_LTS_CREDS env var set") unless ENV["RAILS_LTS_CREDS"]

    Hatchet::Runner.new("rails42_default_ruby", config: rails_lts_config).tap do |app|
      app.before_deploy do
        Pathname("Gemfile").write("ruby '2.7.2'", mode: "a")
        Pathname("public/assets/manifest-ccf61eade4793995271564a4767ce6b6.json").tap {|p| p.dirname.mkpath; FileUtils.touch(p) }
      end

      app.deploy do
        expect(app.output).to include("Detected manifest file, assuming assets were compiled locally")
      end
    end
  end

  it "should skip asset compilation when deployed with OLD manifest file" do
    skip("Need RAILS_LTS_CREDS env var set") unless ENV["RAILS_LTS_CREDS"]

    Hatchet::Runner.new("rails42_default_ruby", config: rails_lts_config).tap do |app|
      app.before_deploy do
        Pathname("Gemfile").write("ruby '2.7.2'", mode: "a")
        Pathname("public/assets/.sprockets-manifest-040763ccc5036260c52c6adcf77d73f7.json").tap {|p| p.dirname.mkpath; FileUtils.touch(p) }
      end

      app.deploy do
        expect(app.output).to include("Detected manifest file, assuming assets were compiled locally")
      end
    end
  end
end
