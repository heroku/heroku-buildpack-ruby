require_relative 'spec_helper'

describe "Rails 2.3.x" do
  it "should deploy on ruby 1.8.7 on cedar" do
    app = Hatchet::Runner.new('rails23_mri_187').setup!
    app.heroku.put_stack(app.name, "cedar")
    app.deploy do |app, heroku|
      expect(successful_body(app)).to eq("hello")
    end
  end
end
