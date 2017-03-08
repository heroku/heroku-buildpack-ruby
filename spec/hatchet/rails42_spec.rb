require_relative '../spec_helper'

describe "Rails 4.2.x" do

  it "set RAILS_SERVE_STATIC_FILES" do
    Hatchet::Runner.new("rails42_scaffold").deploy do |app, heroku|
      output = app.run("rails runner 'puts ENV[%Q{RAILS_SERVE_STATIC_FILES}].present?'")
      expect(output).to match(/true/)
    end
  end
end
