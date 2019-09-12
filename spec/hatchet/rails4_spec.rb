require_relative '../spec_helper'

describe "Rails 4.x" do
  it "set RAILS_SERVE_STATIC_FILES" do
    Hatchet::Runner.new("rails42_scaffold").deploy do |app, heroku|
      output = app.run("rails runner 'puts ENV[%Q{RAILS_SERVE_STATIC_FILES}].present?'")
      expect(output).to match(/true/)
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
      run!(%Q{mkdir public/assets})
      run!(%Q{echo #{string} > public/assets/file.txt})
      run!(%Q{git add -A; git commit -m 'adding file.txt'})
      app.push!

      # Second Deploy
      run!(%Q{echo #{new_string} > public/assets/file.txt})
      run!(%Q{git add -A; git commit -m 'updating file.txt'})
      app.push!

      # Asserts
      result = app.run('cat public/assets/file.txt')
      expect(result).not_to match(string)
      expect(result).to match(new_string)
    end
  end

  it "should detect rails successfully" do
    Hatchet::App.new('rails4-manifest').in_directory_fork do
      expect(LanguagePack::Rails4.use?).to eq(true)
    end
    Hatchet::App.new('rails4-manifest').in_directory_fork do
      expect(LanguagePack::Rails3.use?).to eq(false)
    end
  end

  it "should skip asset compilation when deployed with manifest file" do
    Hatchet::Runner.new("rails4-manifest").deploy do |app, heroku|
      expect(app.output).to include("Detected manifest file, assuming assets were compiled locally")
      expect(app.output).not_to match("Include 'rails_12factor' gem to enable all platform features")
    end
  end

  it "detects new manifest file (sprockets 3.x: .sprockets-manifest-<digest>.json) Rails 4.2" do
    Hatchet::Runner.new("rails42_sprockets3_manifest").deploy do |app, heroku|
      expect(app.output).to include("Detected manifest file, assuming assets were compiled locally")
    end
  end

  it "upgraded from 3 to 4.2 missing ./bin still works" do
    Hatchet::Runner.new("rails3-to-4-no-bin").deploy do |app, heroku|
      expect(app.output).to include("Asset precompilation completed")

      expect(app.output).to match("WARNING")
      expect(app.output).to match("Include 'rails_12factor' gem to enable all platform features")

      output = app.run("rails runner 'puts %Q{hello} + %Q{world}'")
      expect(output).to match('helloworld')
    end
  end

  it "fails compile if assets:precompile fails rails 4.2" do
    Hatchet::Runner.new("rails4-fail-assets-compile", allow_failure: true).deploy do |app, heroku|
      expect(app.output).to include("raising on assets:precompile on purpose")
      expect(app).not_to be_deployed
    end
  end
end
