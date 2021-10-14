require_relative '../spec_helper'

describe "Bugs" do
  it "nokogiri should use the system libxml2" do
    Hatchet::Runner.new("nokogiri_160").deploy do |app|
      expect(app.output).to match("nokogiri")
      expect(app.run("bundle exec nokogiri -v")).not_to include("WARNING: Nokogiri was built against LibXML version")
    end
  end

  context "database connections" do
    it "fails with better error message" do
      Hatchet::Runner.new("ruby-getting-started", allow_failure: true).tap do |app| 
        app.before_deploy do
          Pathname("Rakefile").write(<<~EOM)
            require 'bundler'
            Bundler.require(:default)

            require 'active_record'

            task "assets:precompile" do
              # Try to connect to a database that doesn't exist yet
              ActiveRecord::Base.establish_connection
              ActiveRecord::Base.connection.execute("")
            end
          EOM
        end

        app.deploy do
          expect(app.output).to match("https://devcenter.heroku.com/articles/pre-provision-database")
        end
      end
    end
  end
end
