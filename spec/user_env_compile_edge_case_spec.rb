require 'spec_helper'

describe "User env compile" do
  it "should not cause problems with warnings" do
    app = Hatchet::Runner.new("mri_210", labs: "user-env-compile")
    app.setup!
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
end
