require_relative 'spec_helper'

describe "Rails 3.x" do
  it "should deploy on ruby 1.9.3" do
    Hatchet::AnvilApp.new("rails3_mri_193", :buildpack => buildpack).deploy do |app, heroku|
      add_database(app, heroku)
      expect(app).to be_deployed
      expect(Excon.get("http://#{app.name}.herokuapp.com").body).to eq("hello")
    end
  end

  context "when not using the rails gem" do
    it "should deploy on ruby 1.9.3" do
      Hatchet::AnvilApp.new("railties3_mri_193", :buildpack => buildpack).deploy do |app, heroku, output|
        add_database(app, heroku)
        expect(app).to be_deployed
        expect(output).to match("Detecting buildpack... done, .+Ruby/Rails")
        expect(Excon.get("http://#{app.name}.herokuapp.com").body).to eq("hello")
      end
    end
  end
end
