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
    abi_version = LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER.dup
    abi_version[-1] = "0" # turn 2.6.6 into 2.6.0
    pending("Must enable HATCHET_EXPENSIVE_MODE") unless ENV["HATCHET_EXPENSIVE_MODE"]

    Hatchet::Runner.new("default_ruby").tap do |app|
      app.before_deploy do
        run!(%Q{printf "\nBUNDLED WITH\n   1.0.1\n" >> Gemfile.lock})
      end
      app.deploy do
        expect(app.output).to match("Installing dependencies using bundler 1.")
        expect(app.output).to match("BUNDLE_GLOBAL_PATH_APPENDS_RUBY_SCOPE=1")

        # app.run_multi("ls vendor/bundle/ruby/#{abi_version}/gems") do |ls_output|
        #   expect(ls_output).to match("rake-")
        # end

        app.run("which -a rake") do |which_rake|
          expect(which_rake).to include("/app/vendor/bundle/bin/rake")
          expect(which_rake).to include("/app/vendor/bundle/ruby/#{abi_version}/bin/rake")
        end
      end
    end
  end
end
