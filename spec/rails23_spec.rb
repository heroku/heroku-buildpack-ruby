require_relative 'spec_helper'

describe "Rails 2.3.x" do
  it "should deploy on ruby 1.8.7" do
    Hatchet::AnvilApp.new("rails23_mri_187", :buildpack => buildpack).deploy do |app, heroku|
      add_database(app, heroku)
      expect(app).to be_deployed
      expect(Excon.get("http://#{app.name}.herokuapp.com").body).to eq("hello")
    end
  end
end
