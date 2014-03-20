require_relative 'spec_helper'

describe "Bugs" do
  context "MRI 1.8.7" do
    it "should install nokogiri" do
      Hatchet::Runner.new("mri_187_nokogiri").deploy do |app|
        expect(app.output).to match("Installing nokogiri")
        expect(app.output).to match("Your bundle is complete!")
      end
    end
  end

  it "nokogiri should use the system libxml2" do
    Hatchet::Runner.new("nokogiri_160").deploy do |app|
      expect(app.output).to match("nokogiri")
      expect(app.run("bundle exec nokogiri -v")).not_to include("WARNING: Nokogiri was built against LibXML version")
    end
  end

  context "database connections" do
    it "fails with better error message" do
      Hatchet::Runner.new("connect_to_database_on_first_push", allow_failure: true).deploy do |app|
        expect(app.output).to match("https://devcenter.heroku.com/articles/pre-provision-database")
      end
    end
  end
end
