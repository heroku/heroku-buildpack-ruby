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
      expect(app.output).to include("Detected manifest file, assuming assets were compiled locally")
      expect(app.output).not_to match("Include 'rails_12factor' gem to enable all platform features")
    end
  end

  it "detects new manifest file (sprockets 3.x: .sprockets-manifest-<digest>.json)" do
    Hatchet::Runner.new("rails42_sprockets3_manifest").deploy do |app, heroku|
      expect(app.output).to include("Detected manifest file, assuming assets were compiled locally")
    end
  end

  it "upgraded from 3 to 4 missing ./bin still works" do
    Hatchet::Runner.new("rails3-to-4-no-bin").deploy do |app, heroku|
      expect(app.output).to include("Asset precompilation completed")

      expect(app.output).to match("WARNING")
      expect(app.output).to match("Include 'rails_12factor' gem to enable all platform features")

      output = app.run("rails runner 'puts %Q{hello} + %Q{world}'")
      expect(output).to match('helloworld')
    end
  end

  # it "works with windows" do
  #   pending("failing due to free dynos not being able to have more than 1 process type")
  #   Hatchet::Runner.new("rails4_windows_mri193").deploy do |app, heroku|
  #     result = app.run("rails -v")
  #     expect(result).to match("4.0.0")
  #     result = app.run("rake -T")
  #     expect(result).to match("assets:precompile")

  #     result = app.run("bundle show rails")
  #     expect(result).to match("rails-4.0.0")
  #     expect(app.output).to match("Removing `Gemfile.lock`")

  #     before_final_warnings = app.output.split("Bundle completed").first
  #     expect(before_final_warnings).to match("Removing `Gemfile.lock`")
  #   end
  # end

  it "fails compile if assets:precompile fails" do
    Hatchet::Runner.new("rails4-fail-assets-compile", allow_failure: true).deploy do |app, heroku|
      expect(app.output).to include("raising on assets:precompile on purpose")
      expect(app).not_to be_deployed
    end
  end

  it "should not override user settings" do
    app = Hatchet::Runner.new("rails4-env-assets-compile")
    app.setup!
    app.set_config("RAILS_ENV" => "staging")
    app.deploy do |a, heroku|
      expect(a.output).to include("w00t")
    end
  end
end
