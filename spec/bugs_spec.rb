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
      expect(app.output).to match("Installing nokogiri")
      expect(app.run("bundle exec nokogiri -v")).not_to include("ARNING: Nokogiri was built against LibXML version")
    end
  end

  it "retries on bad bundler install" do
    Hatchet::Runner.new("bad_gemfile_on_install", allow_failure: true).deploy do |app|
      expect(app).not_to be_deployed

      exp = Regexp.escape("Retrying (2/3): bundle install")
      expect(app.output).to match(exp)

      exp = Regexp.escape("Retrying (3/3): bundle install")
      expect(app.output).to match(exp)
    end
  end
end
