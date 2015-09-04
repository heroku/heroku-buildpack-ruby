require_relative 'spec_helper'

describe "Rails 2.3.x" do
  it "should deploy on ruby 1.9.3 on cedar-14" do
    app = Hatchet::Runner.new('rails23_mri_193').setup!
    app.heroku.put_stack(app.name, "cedar-14")
    app.deploy do |app, heroku|
      expect(successful_body(app)).to eq("hello")
    end
  end
end
