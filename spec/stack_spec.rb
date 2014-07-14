require_relative "spec_helper"

describe "Stack Changes" do
  it "should reinstall gems on stack change" do
    Hatchet::Runner.new("mri_193").deploy do |app, heroku|
      heroku.put_stack(app.name, "cedar-14")
      `git commit --allow-empty -m "cedar-14 migrate"`

      app.push!
      puts app.output
      expect(app.output).to match("Installing rack")
      expect(app.output).to match("Changing stack")
    end
  end

  it "should not reinstall gems if the stack did not change" do
    Hatchet::Runner.new("mri_193").deploy do |app, heroku|
      heroku.put_stack(app.name, "cedar")
      `git commit --allow-empty -m "cedar migrate"`

      app.push!
      puts app.output
      expect(app.output).to match("Using rack")
    end
  end
end
