require_relative 'spec_helper'

describe "Bugs" do
  context "MRI 1.8.7 on cedar" do
    it "should install nokogiri" do
      app = Hatchet::Runner.new('mri_187_nokogiri').setup!
      app.heroku.put_stack(app.name, "cedar")
      app.deploy do |app, heroku|
        expect(app.output).to match("Installing nokogiri")
        expect(app.output).to match("Bundle complete")
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

  context "bad versions" do
    it "fails with better error message" do
      Hatchet::Runner.new("bad_ruby_version", allow_failure: true).deploy do |app|
        expect(app.output).to match("devcenter.heroku.com/articles/ruby-support")
      end
    end
  end
end
