require_relative '../spec_helper'

describe "Heroku ruby getting started" do
  it "works on Heroku-24" do
    Hatchet::Runner.new("ruby-getting-started", stack: "heroku-24").deploy do |app|
      expect(app.output).to_not include("Purging Cache")
      expect(app.output).to include("Fetching puma")

      secret_key_base = app.run("echo $SECRET_KEY_BASE")

      # Re-deploy with cache
      run!("git commit --allow-empty -m empty")
      app.push!

      # Assert used cached gems
      expect(app.output).to_not include("Fetching puma")

      # Assert no warnings from `cp`
      # https://github.com/heroku/heroku-buildpack-ruby/pull/1586/files#r2064284286
      expect(app.output).to_not include("cp --help")
      expect(app.run("which ruby").strip).to eq("/app/bin/ruby")

      environment_variables = app.run("env")
      expect(environment_variables).to match("PUMA_PERSISTENT_TIMEOUT")
      # Assert cached value persisted
      expect(environment_variables).to match("SECRET_KEY_BASE=#{secret_key_base}")

      profile_d = app.run("cat .profile.d/ruby.sh")
        .strip
        .split("\n")
        .sort
        .join("\n")

      # SECRET_KEY_BASE has a non-deterministic value, assert it exists but remove from equality check
      expect(profile_d).to match("SECRET_KEY_BASE")
      profile_d.gsub!(/$\s*export SECRET_KEY_BASE=.*/, "")

      expect(profile_d).to eq(<<~EOF.strip)
        export BUNDLE_BIN=${BUNDLE_BIN:-vendor/bundle/bin}
        export BUNDLE_DEPLOYMENT=${BUNDLE_DEPLOYMENT:-1}
        export BUNDLE_PATH=${BUNDLE_PATH:-vendor/bundle}
        export BUNDLE_WITHOUT=${BUNDLE_WITHOUT:-development:test}
        export DISABLE_SPRING="1"
        export GEM_PATH="$HOME/vendor/bundle/ruby/3.4.0:$GEM_PATH"
        export LANG=${LANG:-en_US.UTF-8}
        export MALLOC_ARENA_MAX=${MALLOC_ARENA_MAX:-2}
        export PATH="$HOME/bin:$HOME/vendor/bundle/bin:$HOME/vendor/bundle/ruby/3.4.0/bin:$PATH"
        export PUMA_PERSISTENT_TIMEOUT=${PUMA_PERSISTENT_TIMEOUT:-95}
        export RACK_ENV=${RACK_ENV:-production}
        export RAILS_ENV=${RAILS_ENV:-production}
        export RAILS_LOG_TO_STDOUT=${RAILS_LOG_TO_STDOUT:-enabled}
        export RAILS_SERVE_STATIC_FILES=${RAILS_SERVE_STATIC_FILES:-enabled}
      EOF
    end
  end

  it "works on Heroku-22" do
    Hatchet::Runner.new("ruby-getting-started", stack: "heroku-22").deploy do |app|
      # Re-deploy with cache
      run!("git commit --allow-empty -m empty")
      app.push!

      # Assert no warnings from `cp`
      # https://github.com/heroku/heroku-buildpack-ruby/pull/1586/files#r2064284286
      expect(app.output).to_not include("cp --help")
      expect(app.run("which ruby").strip).to eq("/app/bin/ruby")
    end
  end
end
