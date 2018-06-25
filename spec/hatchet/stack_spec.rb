require_relative "../spec_helper"

describe "Stack Changes" do
  xit "should reinstall gems on stack change" do
    app = Hatchet::Runner.new('default_ruby', stack: "heroku-18").setup!
    app.deploy do |app, heroku|
      app.update_stack("heroku-16")
      run!('git commit --allow-empty -m "heroku-16 migrate"')

      app.push!
      puts app.output
      expect(app.output).to match("Installing rack 1.5.0")
      expect(app.output).to match("Changing stack")
    end
  end

  it "should not reinstall gems if the stack did not change" do
    app = Hatchet::Runner.new('default_ruby', stack: "heroku-16").setup!
    app.deploy do |app, heroku|
      app.update_stack("heroku-16")
      run!(%Q{git commit --allow-empty -m "cedar migrate"})

      app.push!
      puts app.output
      expect(app.output).to match("Using rack 1.5.0")
    end
  end
end
