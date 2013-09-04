require_relative 'spec_helper'

describe "Rails 2.3.x" do
  it "should deploy on ruby 1.8.7" do
    Hatchet::Runner.new("rails23_mri_187").deploy do |app, heroku|
      add_database(app, heroku)
      expect(successful_body(app)).to eq("hello")
    end
  end
end
