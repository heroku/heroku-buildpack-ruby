require_relative 'spec_helper'

describe "Rails 4.0.x" do
  it "should detect rails successfully" do
    Hatchet::App.new('rails4-manifest').in_directory do
      expect(LanguagePack::Rails4.use?).to eq(true)
    end
    Hatchet::App.new('rails4-manifest').in_directory do
      expect(LanguagePack::Rails3.use?).to eq(false)
    end
  end

  it "should deploy on ruby 2.0.0" do
    Hatchet::Runner.new("rails4-manifest").deploy do |app, heroku|
      add_database(app, heroku)
      expect(app.output).to include("Detected manifest file, assuming assets were compiled locally")
      expect(app.output).not_to match("Include 'rails_12factor' gem to enable all platform features")
    end
  end

  it "upgraded from 3 to 4 missing ./bin still works" do
    Hatchet::Runner.new("rails3-to-4-no-bin").deploy do |app, heroku|
      expect(app.output).to include("Asset precompilation completed")
      add_database(app, heroku)

      expect(app.output).to match("WARNINGS")
      expect(app.output).to match("Include 'rails_12factor' gem to enable all platform features")

      app.run("rails console") do |console|
        console.run("'hello' + 'world'") {|result| expect(result).to match('helloworld')}
      end
    end
  end

  it "works with windows" do
    Hatchet::Runner.new("rails4_windows_mri193").deploy do |app, heroku|
      result = app.run("rails -v")
      expect(result).to match("4.0.0")

      result = app.run("rake -T")
      expect(result).to match("assets:precompile")

      result = app.run("bundle show rails")
      expect(result).to match("rails-4.0.0")

      before_warnings = app.output.split("WARNINGS:").first
      expect(before_warnings).to match("Removing `Gemfile.lock`")
    end
  end

  it "fails compile if assets:precompile fails" do
    Hatchet::Runner.new("rails4-fail-assets-compile", allow_failure: true).deploy do |app, heroku|
      expect(app.output).to include("raising on assets:precompile on purpose")
      expect(app).not_to be_deployed
    end
  end
end
