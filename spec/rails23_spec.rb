require_relative 'spec_helper'

describe "Rails 2.3.x" do
  it "should deploy on ruby 1.8.7 on cedar" do
    app = Hatchet::Runner.new('rails23_mri_187').setup!
    app.heroku.put_stack(app.name, "cedar")
    app.deploy do |app, heroku|
      add_database(app, heroku)
      expect(successful_body(app)).to eq("hello")
    end
  end

  it "should create config/*.yml files" do
    app = Hatchet::Runner.new('rails23_mri_187').setup!
    app.heroku.put_stack(app.name, "cedar")
    app.deploy do |app, heroku|
      expect(app.output).to match("Installing nokogiri")
      expect(app.output).to match("Bundle complete")
    end
  end
end
