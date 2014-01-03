require_relative 'spec_helper'

describe "Rails 3.x" do
  it "should deploy on ruby 1.9.3" do
    Hatchet::Runner.new("rails3_mri_193").deploy do |app, heroku|
      expect(app.output).to include("Asset precompilation completed")
      add_database(app, heroku)

      expect(app.output).to match("WARNINGS")
      expect(app.output).to match("Add 'rails_12factor' gem to your Gemfile to skip plugin injection")

      ls = app.run("ls vendor/plugins")
      expect(ls).to match("rails3_serve_static_assets")
      expect(ls).to match("rails_log_stdout")

      expect(successful_body(app)).to eq("hello")
    end
  end

  it "should not have warnings when using the rails_12factor gem" do
    Hatchet::Runner.new("rails3_12factor").deploy do |app, heroku|
      add_database(app, heroku)
      expect(app.output).not_to match("Add 'rails_12factor' gem to your Gemfile to skip plugin injection")
      expect(successful_body(app)).to eq("hello")
    end
  end

  it "should only display the correct plugin warning" do
    Hatchet::Runner.new("rails3_one_plugin").deploy do |app, heroku|
      add_database(app, heroku)
      expect(app.output).not_to match("rails_log_stdout")
      expect(app.output).to match("rails3_serve_static_assets")
      expect(app.output).to match("Add 'rails_12factor' gem to your Gemfile to skip plugin injection")
      expect(successful_body(app)).to eq("hello")
    end
  end

  context "when not using the rails gem" do
    it "should deploy on ruby 1.9.3" do
      Hatchet::Runner.new("railties3_mri_193").deploy do |app, heroku|
        expect(app.output).to include("Asset precompilation completed")
        add_database(app, heroku)
        expect(app.output).to match("Ruby/Rails")
        expect(successful_body(app)).to eq("hello")
      end
    end
  end

  it "fails compile if assets:precompile fails" do
    Hatchet::Runner.new("rails3-fail-assets-compile", allow_failure: true).deploy do |app, heroku|
      expect(app.output).to include("raising on assets:precompile on purpose")
      expect(app).not_to be_deployed
    end
  end
end
