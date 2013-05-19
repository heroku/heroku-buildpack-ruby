require_relative 'spec_helper'

describe "Ruby Versions" do
  it "should deploy ruby 1.8.7 properly" do
    Hatchet::AnvilApp.new("mri_187", :buildpack => buildpack).deploy do |app, heroku, output|
      expect(app).to be_deployed
      expect(successful_body(app)).to match("ruby 1.8.7")
    end
  end

  it "should deploy ruby 1.9.2 properly" do
    Hatchet::AnvilApp.new("mri_192", :buildpack => buildpack).deploy do |app, heroku, output|
      expect(app).to be_deployed
      expect(successful_body(app)).to match("ruby 1.9.2")
    end
  end

  it "should deploy ruby 1.9.2 properly (git)" do
    Hatchet::GitApp.new("mri_192", :buildpack => git_repo).deploy do |app, heroku, output|
      expect(app).to be_deployed
      expect(successful_body(app)).to match("ruby 1.9.2")
    end
  end

  it "should deploy ruby 1.9.3 properly" do
    Hatchet::AnvilApp.new("mri_193", :buildpack => buildpack).deploy do |app, heroku, output|
      expect(app).to be_deployed
      expect(successful_body(app)).to match("ruby 1.9.3")
    end
  end

  it "should deploy ruby 2.0.0 properly" do
    Hatchet::AnvilApp.new("mri_200", :buildpack => buildpack).deploy do |app, heroku|
      expect(app).to be_deployed
      expect(successful_body(app)).to match("ruby 2.0.0")
    end
  end
end
