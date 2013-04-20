require_relative 'spec_helper'

describe "Rails 3.x" do
  it "should deploy on ruby 1.9.3" do
    Hatchet::AnvilApp.new("rails3_mri_193", :buildpack => buildpack).deploy do |app, heroku|
      add_database(app, heroku)
      expect(app).to be_deployed
      expect(successful_body(app)).to eq("hello")
    end
  end

  context "when not using the rails gem" do
    it "should deploy on ruby 1.9.3" do
      Hatchet::AnvilApp.new("railties3_mri_193", :buildpack => buildpack).deploy do |app, heroku, output|
        add_database(app, heroku)
        expect(app).to be_deployed
        expect(output).to match("Ruby/Rails")
        expect(successful_body(app)).to eq("hello")
      end
    end
  end
end
