require_relative 'spec_helper'

describe "Ruby Versions" do
  it "should deploy ruby 1.8.7 properly" do
    Hatchet::AnvilApp.new("mri_187", :buildpack => buildpack).deploy do |app, heroku, output|
      expect(app).to be_deployed
      expect(Excon.get("http://#{app.name}.herokuapp.com").body.chomp).to eq("ruby 1.8.7 (2012-10-12 patchlevel 371) [x86_64-linux]")
    end
  end

  it "should deploy ruby 1.9.2 properly" do
    Hatchet::AnvilApp.new("mri_192", :buildpack => buildpack).deploy do |app, heroku, output|
      expect(app).to be_deployed
      expect(Excon.get("http://#{app.name}.herokuapp.com").body.chomp).to eq("ruby 1.9.2p320 (2012-04-20 revision 35421) [x86_64-linux]")
    end
  end

  it "should deploy ruby 1.9.2 properly (git)" do
    Hatchet::GitApp.new("mri_192", :buildpack => git_repo).deploy do |app, heroku, output|
      expect(app).to be_deployed
      expect(Excon.get("http://#{app.name}.herokuapp.com").body.chomp).to eq("ruby 1.9.2p320 (2012-04-20 revision 35421) [x86_64-linux]")
    end
  end

  it "should deploy ruby 1.9.3 properly" do
    Hatchet::AnvilApp.new("mri_193", :buildpack => buildpack).deploy do |app, heroku, output|
      puts output
      expect(app).to be_deployed
      expect(Excon.get("http://#{app.name}.herokuapp.com").body.chomp).to eq("ruby 1.9.3p392 (2013-02-22 revision 39386) [x86_64-linux]")
    end
  end

  it "should deploy ruby 2.0.0 properly" do
    Hatchet::AnvilApp.new("mri_200", :buildpack => buildpack).deploy do |app, heroku|
      expect(app).to be_deployed
      expect(Excon.get("http://#{app.name}.herokuapp.com").body.chomp).to eq("ruby 2.0.0p0 (2013-02-24 revision 39474) [x86_64-linux]")
    end
  end
end
