require_relative 'spec_helper'

describe "Rails 4.x" do
  it "should deploy on ruby 2.0.0" do
    Hatchet::Runner.new("rails4-manifest").deploy do |app, heroku|
      add_database(app, heroku)
      expect(app.output).to include("Detected manifest file, assuming assets were compiled locally")
      expect(app.output).not_to match("Include 'rails_12factor' gem to enable all platform features")
    end
  end

  it "upgraded from 3 to 4 missing ./bin still works" do
    Hatchet::Runner.new("rails3-to-4-no-bin").deploy do |app, heroku|
      expect(app.output).to include("Asset precompilation completed")
      add_database(app, heroku)

      expect(app.output).to match("WARNINGS")
      expect(app.output).to match("Include 'rails_12factor' gem to enable all platform features")

      app.run("rails console") do |console|
        console.run("'hello' + 'world'") {|result| expect(result).to match('helloworld')}
      end
    end
  end

  it "works with windows" do
      result = app.run("rails -v")
      expect(result).to match("4.0.0")

      result = app.run("rake -T")
      expect(result).to match("assets:precompile")

      result = app.run("bundle show rails")
      expect(result).to match("rails-4.0.0")
    end
  end
end
