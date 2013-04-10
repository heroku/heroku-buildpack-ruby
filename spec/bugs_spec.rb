require_relative 'spec_helper'

describe "Bugs" do
  context "MRI 1.8.7" do
    it "should install nokogiri" do
      Hatchet::AnvilApp.new("mri_187_nokogiri", :buildpack => buildpack).deploy do |app, heroku, output|
        expect(app).to be_deployed
      end
    end
  end
end
