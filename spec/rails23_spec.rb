require_relative 'spec_helper'

describe "Rails 2.3.x" do
  it "should deploy on ruby 1.9.3 on cedar-14" do
    app = Hatchet::Runner.new('rails23_mri_193').setup!
    app.heroku.put_stack(app.name, "cedar-14")
    app.deploy do |app, heroku|
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
