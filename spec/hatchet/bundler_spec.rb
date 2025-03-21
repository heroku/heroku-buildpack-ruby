require 'spec_helper'

describe "Bundler" do
  it "can be configured with BUNDLE_WITHOUT env var with spaces in it" do
    Hatchet::Runner.new("default_ruby", config: {"BUNDLE_WITHOUT" => "foo bar baz"}).tap do |app|
      app.deploy do
        expect(app.output).to match("BUNDLE_WITHOUT='foo:bar:baz'")
        expect(app.output).to match("Your BUNDLE_WITHOUT contains a space")
      end
    end
  end

  it "deploys with version 1.x" do
    pending("Must enable HATCHET_EXPENSIVE_MODE") unless ENV["HATCHET_EXPENSIVE_MODE"]

    Hatchet::Runner.new("default_ruby").tap do |app|
      app.before_deploy do
        set_bundler_version(version: "1.17.3")
        Pathname("Gemfile.lock").write(<<~EOF, mode: "a")

          RUBY VERSION
            ruby 3.1.6
        EOF
      end
      app.deploy do
        expect(app.output).to match("Deprecating bundler 1.17.3")

        app.run("which -a rake") do |which_rake|
          expect(which_rake).to include("/app/vendor/bundle/bin/rake")
        end
      end
    end
  end
end
