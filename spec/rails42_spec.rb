require_relative 'spec_helper'

describe "Rails 4.2.x" do

  it "set RAILS_SERVE_STATIC_FILES" do
    Hatchet::Runner.new("rails42_scaffold").deploy do |app, heroku|
      ReplRunner.new(:rails_console, "heroku run bin/rails console -a #{app.name}").run do |console|
        console.run("ENV['RAILS_SERVE_STATIC_FILES'].present?") { |result| expect(result).to match(/true/) }
      end
    end
  end
end
