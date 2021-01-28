require_relative '../spec_helper'

describe "Rails 3.x" do
  it "should deploy and inject plugins" do
    skip("Need RAILS_LTS_CREDS env var set") unless ENV["RAILS_LTS_CREDS"]

    Hatchet::Runner.new("rails3_default_ruby", config: rails_lts_config).tap do |app|
      app.before_deploy do
        Pathname("Gemfile").write("ruby '2.7.2'", mode: "a")
      end

      app.deploy do
        # Rails 3 doesn't work with Postgres 8+ out of the box and Rails
        # LTS hasn't patched this yet. We're skipping asset compilation for now
        # by deleting the Rakefile
        #
        # expect(app.output).to include("Asset precompilation completed")

        expect(app.output).to match("WARNING")
        expect(app.output).to match("Add 'rails_12factor' gem to your Gemfile to skip plugin injection")

        ls = app.run("ls vendor/plugins")
        expect(ls).to match("rails3_serve_static_assets")
        expect(ls).to match("rails_log_stdout")
      end
    end
  end
end
