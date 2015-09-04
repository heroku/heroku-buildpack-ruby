require_relative "spec_helper"

describe "Stack Changes" do
  xit "should reinstall gems on stack change" do
    app = Hatchet::Runner.new('mri_200').setup!
    app.heroku.put_stack(app.name, "cedar-14")
    app.deploy do |app, heroku|
      heroku.put_stack(app.name, "cedar")
      `git commit --allow-empty -m "cedar-14 migrate"`

      app.push!
      puts app.output
      expect(app.output).to match("Installing rack 1.5.0")
      expect(app.output).to match("Changing stack")
    end
  end

  it "should not reinstall gems if the stack did not change" do
    app = Hatchet::Runner.new('mri_200').setup!
    app.heroku.put_stack(app.name, "cedar-14")
    app.deploy do |app, heroku|
      heroku.put_stack(app.name, "cedar-14")
      `git commit --allow-empty -m "cedar migrate"`

      app.push!
      puts app.output
      expect(app.output).to match("Using rack 1.5.0")
    end
  end
end
