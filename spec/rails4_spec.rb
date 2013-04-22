require_relative 'spec_helper'

describe "Rails 4.x" do
  it "should deploy on ruby 1.9.3" do
    Hatchet::AnvilApp.new("rails4-manifest", :buildpack => buildpack).deploy do |app, heroku, output|
      add_database(app, heroku)
      expect(app).to be_deployed
      expect(output).to include("Detected manifest file, assuming assets were compiled locally")
    end
  end

end
