require_relative 'spec_helper'

describe "Rails 4.1.x" do
  it "should detect rails successfully" do
    Hatchet::App.new('rails41_scaffold').in_directory do
      expect(LanguagePack::Rails41.use?).to eq(true)
    end
    Hatchet::App.new('rails41_scaffold').in_directory do
      expect(LanguagePack::Rails4.use?).to eq(false)
    end
  end

  context "without a database.yml" do
    it "should run the database migration correctly" do
      Hatchet::Runner.new("rails41_scaffold").deploy do |app, heroku|
        app.run("rm config/database.yml")
        add_database(app, heroku)
        expect(app.output).not_to include("Writing config/database.yml to read from DATABASE_URL")
        expect(app.run("rake db:migrate")).to include("20140218165801 CreatePeople")
      end
    end
  end

  context "with a database.yml" do
    it "should warn about removing the database.yml and write a new database.yml" do
      Hatchet::Runner.new("rails41_scaffold").deploy do |app, heroku|
        app.run("touch config/database.yml")
        add_database(app, heroku)
        expect(app.output).to include("You have your database.yml file checked into git.")
        expect(app.output).to include("Best practice is to remove it from version control.")
        expect(app.output).to include("Writing config/database.yml to read from DATABASE_URL")
        expect(app.run("rake db:migrate")).to include("20140218165801 CreatePeople")
      end
    end
  end

  it "should handle secrets.yml properly" do
    Hatchet::Runner.new("rails41_scaffold").deploy do |app, heroku|
      add_database(app, heroku)
      ReplRunner.new(:rails_console, "heroku run bin/rails console -a #{app.name}").run do |console|
        console.run("ENV['SECRET_KEY_BASE'] == Rails.application.config.secrets.secret_key_base") {|result| expect(result).not_to eq("true") }
      end
    end
  end
end
