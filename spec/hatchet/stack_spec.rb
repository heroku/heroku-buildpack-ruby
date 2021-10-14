require_relative "../spec_helper"

describe "Stack Changes" do
  xit "should reinstall gems on stack change" do
    Hatchet::Runner.new('default_ruby', stack: "heroku-18").deploy do |app|
      app.update_stack("heroku-20")
      run!('git commit --allow-empty -m "heroku-20 migrate"')

      app.push!

      expect(app.output).to match("Installing rack")
      expect(app.output).to match("Changing stack")
    end
  end

  it "should not reinstall gems if the stack did not change" do
    Hatchet::Runner.new('default_ruby', stack: "heroku-20").deploy do |app|
      app.update_stack("heroku-20")
      run!(%Q{git commit --allow-empty -m "cedar migrate"})

      app.push!
      puts app.output
      expect(app.output).to match("Using rack")
    end
  end
end
