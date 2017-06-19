require_relative '../spec_helper'

describe "Rails 2.3.x" do
  it "should deploy on ruby 1.9.3 on cedar-14" do
    app = Hatchet::Runner.new('rails23_mri_193', stack: "cedar-14").setup!
    app.deploy do |app, heroku|
      # assert deploy is successful
    end
  end
end
