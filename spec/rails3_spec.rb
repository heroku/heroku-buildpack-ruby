require_relative 'spec_helper'

describe "Rails 3.x" do
  it "should deploy on ruby 1.9.3" do
    Hatchet::Runner.new("rails3_mri_193").deploy do |app, heroku|
      expect(app.output).to include("Asset precompilation completed")
      add_database(app, heroku)
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
end
