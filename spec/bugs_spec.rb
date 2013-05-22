require_relative 'spec_helper'

describe "Bugs" do
  context "MRI 1.8.7" do
    it "should install nokogiri" do
      Hatchet::AnvilApp.new("mri_187_nokogiri").deploy do |app, heroku, output|
        expect(output).to match("Installing nokogiri")
        expect(output).to match("Your bundle is complete!")
      end
    end
  end
end
