require_relative 'spec_helper'

describe "Rails 4.x" do
  it "should deploy on ruby 1.9.3" do
    Hatchet::Runner.new("rails4-manifest").deploy do |app, heroku|
      add_database(app, heroku)
      expect(app.output).to include("Detected manifest file, assuming assets were compiled locally")
    end
  end

  it "upgraded from 3 to 4 missing ./bin still works" do
    Hatchet::Runner.new("rails3-to-4-no-bin").deploy do |app, heroku|
      expect(app.output).to include("Asset precompilation completed")
      add_database(app, heroku)

      app.run("rails console") do |console|
        console.run("'hello' + 'world'") {|result| expect(result).to match('helloworld')}
      end
    end
  end
end
