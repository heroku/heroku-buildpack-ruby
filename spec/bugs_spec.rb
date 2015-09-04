require_relative 'spec_helper'

describe "Bugs" do
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
