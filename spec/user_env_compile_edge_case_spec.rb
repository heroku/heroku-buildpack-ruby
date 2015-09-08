require 'spec_helper'

describe "User env compile" do
  it "should not cause problems with warnings" do
    app = Hatchet::Runner.new("mri_214")
    app.setup!
    app.heroku.put_stack(app.name, 'cedar-14')
    app.set_config("RUBY_HEAP_MIN_SLOTS" => "1000000")
    app.deploy do |app|
      expect(app.run("bundle version")).to match(LanguagePack::Ruby::BUNDLER_VERSION)
    end
  end

  it "DATABASE_URL is present even without user-env-compile" do
    Hatchet::Runner.new("database_url_expected_in_rakefile").deploy do |app|
      expect(app.output).to match("Asset precompilation completed")
    end
  end

  it "allows weird characters in the env" do
    app = Hatchet::Runner.new("rails41_scaffold")
    app.setup!
    app.set_config("BAD VALUE"      => %Q{ )(*&^%$#'$'\n''@!~\'\ })
    app.set_config(%Q{ un"matched } => "bad key" )
    app.deploy do |app|
      expect(app.output).to match("Launching")
    end
  end
end
