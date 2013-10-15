require_relative 'spec_helper'

describe "Rails 4.x" do
  it "should deploy on ruby 1.9.3" do
    Hatchet::AnvilApp.new("rails4-manifest").deploy do |app, heroku|
      add_database(app, heroku)
      expect(app.output).to include("Detected manifest file, assuming assets were compiled locally")
    end
  end

end
