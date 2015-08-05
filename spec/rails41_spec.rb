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

  it "should be able to run a migration without heroku specific database.yml" do
    Hatchet::Runner.new("rails41_scaffold").deploy do |app, heroku|
      expect(app.output).not_to include("Writing config/database.yml to read from DATABASE_URL")
      expect(app.run("rake db:migrate")).to include("20140218165801 CreatePeople")
    end
  end

  it "should handle secrets.yml properly" do
    Hatchet::Runner.new("rails41_scaffold").deploy do |app, heroku|
      ReplRunner.new(:rails_console, "heroku run bin/rails console -a #{app.name}").run do |console|
        console.run("ENV['SECRET_KEY_BASE'] == Rails.application.config.secrets.secret_key_base") {|result| expect(result).not_to eq("true") }
      end
    end
  end

  it "should not overwrite existing files with cached files" do
    string = SecureRandom.hex(13)
    new_string = SecureRandom.hex(13)

    Hatchet::Runner.new("rails41_scaffold").deploy do |app, heroku|
      # First Deploy
      `mkdir public/assets`
      `echo #{string} > public/assets/file.txt`
      `git add -A; git commit -m 'adding file.txt'`
      app.push!

      # Second Deploy
      `echo #{new_string} > public/assets/file.txt`
      `git add -A; git commit -m 'updating file.txt'`
      app.push!

      # Asserts
      result = app.run('cat public/assets/file.txt')
      expect(result).not_to match(string)
      expect(result).to match(new_string)
    end
  end
end
