require_relative '../spec_helper'

describe "Bugs" do
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

  it "detect fails when no Gemfile is present" do
    Hatchet::Runner.new("default_ruby", allow_failure: true).tap do |app|
      app.before_deploy do
        FileUtils.rm("Gemfile")
      end
      app.deploy do |app|
        expect(app.output).to include("A Ruby app on Heroku must have a 'Gemfile' and 'Gemfile.lock' in the root directory of its source code.")
        expect(app).not_to be_deployed
      end
    end
  end
end
