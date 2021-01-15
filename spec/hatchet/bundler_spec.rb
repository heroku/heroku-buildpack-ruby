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

  it "deploys with version 2.x with Ruby 2.5" do
    ruby_version = "2.5.7"
    abi_version = ruby_version.dup
    abi_version[-1] = "0" # turn 2.5.7 into 2.5.0
    pending("Must enable HATCHET_EXPENSIVE_MODE") unless ENV["HATCHET_EXPENSIVE_MODE"]

    Hatchet::Runner.new("default_ruby", run_multi: true, stack: "heroku-18").tap do |app|
      app.before_deploy do
        run!(%Q{echo "ruby '#{ruby_version}'" >> Gemfile})
        run!(%Q{printf "\nBUNDLED WITH\n   2.0.1\n" >> Gemfile.lock})
      end
      app.deploy do
        expect(app.output).to match("Installing dependencies using bundler 2.")
        expect(app.output).to_not match("BUNDLE_GLOBAL_PATH_APPENDS_RUBY_SCOPE=1")

        # Double deploy problem with Ruby 2.5.5
        app.commit!
        app.push!

        app.run_multi("ls vendor/bundle/ruby/#{abi_version}/gems") do |ls_output|
          expect(ls_output).to match("rake-")
        end

        app.run_multi("which -a rake") do |which_rake|
          expect(which_rake).to include("/app/vendor/bundle/bin/rake")
          expect(which_rake).to include("/app/vendor/bundle/ruby/#{abi_version}/bin/rake")
        end
      end
    end
  end

  it "deploys with version 1.x" do
    abi_version = LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER.dup
    abi_version[-1] = "0" # turn 2.6.6 into 2.6.0
    pending("Must enable HATCHET_EXPENSIVE_MODE") unless ENV["HATCHET_EXPENSIVE_MODE"]

    Hatchet::Runner.new("default_ruby", run_multi: true).tap do |app|
      app.before_deploy do
        run!(%Q{printf "\nBUNDLED WITH\n   1.0.1\n" >> Gemfile.lock})
      end
      app.deploy do
        expect(app.output).to match("Installing dependencies using bundler 1.")
        expect(app.output).to match("BUNDLE_GLOBAL_PATH_APPENDS_RUBY_SCOPE=1")

        app.run_multi("ls vendor/bundle/ruby/#{abi_version}/gems") do |ls_output|
          expect(ls_output).to match("rake-")
        end

        app.run_multi("which -a rake") do |which_rake|
          expect(which_rake).to include("/app/vendor/bundle/bin/rake")
          expect(which_rake).to include("/app/vendor/bundle/ruby/#{abi_version}/bin/rake")
        end
      end
    end
  end
end
