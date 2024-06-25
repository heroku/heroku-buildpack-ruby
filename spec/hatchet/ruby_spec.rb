require_relative '../spec_helper'

describe "Ruby apps" do
  describe "with mingw platform" do
    it "is detected as a Windows app" do
      Hatchet::Runner.new("default_ruby").tap do |app|
        app.before_deploy do
          Pathname("Gemfile").write(<<~'EOF')
            source "https://rubygems.org"

            gem "rake"
          EOF

          Pathname("Gemfile.lock").write(<<~'EOF')
            GEM
              remote: https://rubygems.org/
              specs:
                rake (13.2.1)

            PLATFORMS
              x86-mingw32
              ruby

            DEPENDENCIES
              rake

            BUNDLED WITH
               2.5.9
          EOF
        end

        app.deploy do
          expect(app.output).to include("Windows platform detected, preserving `Gemfile.lock`")
        end
      end
    end
  end

  # https://github.com/heroku/heroku-buildpack-ruby/issues/1025
  describe "bin/rake binstub" do
    it "loads git gems at build time when executing `rake`" do
      Hatchet::Runner.new("git_gemspec").tap do |app|
        app.before_deploy do
          File.open("Rakefile", "w+") do |f|
            f.puts(<<~EOF)
            task "assets:precompile" do
              require 'mini_histogram'
              puts "successfully loaded git gem"
            end
            EOF
          end
        end
        app.deploy do
          expect(app.output).to match("successfully loaded git gem")
          expect(app.run("rake assets:precompile")).to match("successfully loaded git gem")
        end
      end
    end

    it "loads bundler into memory" do
      Hatchet::Runner.new("default_ruby").tap do |app|
        app.before_deploy do
          File.open("Rakefile", "w+") do |f|
            f.puts(<<~EOF)
            task "assets:precompile" do
              puts Bundler.methods

              puts "bundler loaded in rake context"
            end
            EOF
          end
        end
        app.deploy do
          expect(app.output).to match("bundler loaded in rake context")
          expect(app.run("rake assets:precompile")).to match("bundler loaded in rake context")
        end
      end
    end

    it "loads custom rake binstub" do
      Hatchet::Runner.new("default_ruby").tap do |app|
        app.before_deploy do
          FileUtils.mkdir_p("bin")

          File.open("bin/rake", "w+") do |f|
            f.puts(<<~EOF)
            #!/usr/bin/env ruby

            puts "rake assets:precompile" # Needed to trigger the `rake -P` task detection
            puts "custom rake binstub called"
            EOF
          end
          FileUtils.chmod("+x", "bin/rake")
        end
        app.deploy do
          expect(app.output).to match("custom rake binstub called")
          expect(app.run("rake")).to match("custom rake binstub called")
        end
      end
    end
  end

  describe "bad ruby version" do
    it "gives a helpful error" do
      Hatchet::Runner.new('ruby_version_does_not_exist', allow_failure: true, stack: DEFAULT_STACK).deploy do |app|
        expect(app.output).to match("The Ruby version you are trying to install does not exist: ruby-2.9.0.lol")
      end
    end
  end

  describe "exporting path" do
    it "puts local bin dir in path" do
      before_deploy = Proc.new do
        FileUtils.mkdir_p("bin")
        File.open("bin/bloop", "w+") do |f|
          f.puts(<<~EOF)
          #!/usr/bin/env bash

          echo "bloop"
          EOF
        end
        FileUtils.chmod("+x", "bin/bloop")

        File.open("Rakefile", "a") do |f|
          f.puts(<<~EOF)
          task "run:bloop" do
            puts `bloop`
            raise "Could not bloop" unless $?.success?
          end
          EOF
        end
      end
      buildpacks = [
        :default,
        "https://github.com/schneems/buildpack-ruby-rake-deploy-tasks"
      ]
      config = { "DEPLOY_TASKS" => "run:bloop"}
      Hatchet::Runner.new('default_ruby', stack: DEFAULT_STACK, buildpacks: buildpacks, config: config, before_deploy: before_deploy).deploy do |app|
        expect(app.output).to match("bloop")
      end
    end
  end

  describe "running Ruby from outside the default dir" do
    it "works" do
      buildpacks = [
        :default,
        "https://github.com/sharpstone/force_absolute_paths_buildpack"
      ]
      config = {FORCE_ABSOLUTE_PATHS_BUILDPACK_IGNORE_PATHS: "BUNDLE_PATH"}


      Hatchet::Runner.new('default_ruby', stack: DEFAULT_STACK, buildpacks: buildpacks, config: config).tap do |app|
        app.before_deploy do
          Pathname("Gemfile").write(<<~'EOF')
            source "https://rubygems.org"

            ruby "~> 3.0.0"

            gem "rake"
          EOF

          Pathname("Gemfile.lock").write(<<~'EOF')
            GEM
              remote: https://rubygems.org/
              specs:
                rake (13.0.6)

            PLATFORMS
              ruby
              x86_64-darwin-20

            DEPENDENCIES
              rake

            RUBY VERSION
              ruby 3.0.3p157

            BUNDLED WITH
               2.3.7
          EOF

          Pathname("Rakefile").write(<<~'EOF')
            task "assets:precompile" do
              out = `cd client && bundle exec ruby -v`
              puts "cd version #{out}"
              unless $?.success?
                puts "Failed: #{out}"
                exit 1
              end
            end
          EOF

          dir = Pathname("client")
          dir.mkpath
          FileUtils.touch(dir.join(".gitkeep"))
        end

        app.deploy do |app|
          expect(app.output).to match("cd version ruby 3.0.3")

          expect(app.run("which ruby").strip).to eq("/app/bin/ruby")
        end
      end
    end
  end

  describe "bundler ruby version matcher" do
    it "installs a version even when not present in the Gemfile.lock" do
      Hatchet::Runner.new('default_ruby', stack: DEFAULT_STACK).tap do |app|
        app.before_deploy do
          Pathname("Gemfile").write(<<~'EOF')
            source "https://rubygems.org"

            ruby "~> 3.0.0"

            gem "sinatra"
          EOF

          Pathname("Gemfile.lock").write(<<~'EOF')
            GEM
              remote: https://rubygems.org/
              specs:
                mustermann (1.1.1)
                  ruby2_keywords (~> 0.0.1)
                rack (2.2.3)
                rack-protection (2.2.0)
                  rack
                ruby2_keywords (0.0.5)
                sinatra (2.2.0)
                  mustermann (~> 1.0)
                  rack (~> 2.2)
                  rack-protection (= 2.2.0)
                  tilt (~> 2.0)
                tilt (2.0.10)

            PLATFORMS
              ruby
              x86_64-darwin-20

            DEPENDENCIES
              sinatra

            BUNDLED WITH
               2.3.7
          EOF

        end

        app.deploy do |app|
          # Intentionally different than the default ruby version
          expect(app.output).to         match("3.0.0")
          expect(app.run("ruby -v")).to match("3.0.0")
        end
      end
    end
  end

  describe "Rake detection" do
    context "Ruby 1.9+" do
      it "runs a rake task if the gem exists" do
        Hatchet::Runner.new('default_with_rakefile').deploy do |app, heroku|
          expect(app.output).to include("foo")
        end
      end
    end
  end

  describe "database configuration" do
    context "no active record" do
      it "writes a heroku specific database.yml" do
        Hatchet::Runner.new("default_ruby").deploy do |app, heroku|
          expect(app.output).to     include("Writing config/database.yml to read from DATABASE_URL")
          expect(app.output).not_to include("Your app was upgraded to bundler")
          expect(app.output).not_to include("Your Ruby version is not present on the next stack")
        end
      end
    end

    context "active record 4.1+" do
      it "doesn't write a heroku specific database.yml" do
        Hatchet::Runner.new("activerecord41_scaffold").deploy do |app, heroku|
          expect(app.output).not_to include("Writing config/database.yml to read from DATABASE_URL")
        end
      end
    end
  end
end

describe "Raise errors on specific gems" do
  it "should raise on sqlite3" do
    Hatchet::Runner.new("sqlite3_gemfile", allow_failure: true).deploy do |app|
      expect(app).not_to be_deployed
      expect(app.output).to include("Detected sqlite3 gem which is not supported")
      expect(app.output).to include("devcenter.heroku.com/articles/sqlite3")
    end
  end
end

describe "No Lockfile" do
  it "should not deploy" do
    Hatchet::Runner.new("no_lockfile", allow_failure: true).deploy do |app|
      expect(app).not_to be_deployed
      expect(app.output).to include("Gemfile.lock required")
    end
  end
end

describe "Rack" do
  it "should not overwrite already set environment variables" do
    custom_env = "FFFUUUUUUU"
    app = Hatchet::Runner.new("default_ruby", config: {"RACK_ENV" => custom_env})

    app.deploy do |app|
      expect(app.run("env")).to match(custom_env)
    end
  end
end

describe "WEB_CONCURRENCY.sh" do
  it "from a preceding buildpack is overwritten by this buildpack" do
    buildpacks = [
      "heroku/nodejs",
      :default
    ]
    before_deploy = -> { run!(%Q{echo "{}" > package.json}) }
    Hatchet::Runner.new('default_ruby', stack: DEFAULT_STACK, buildpacks: buildpacks, before_deploy: before_deploy).deploy do |app|
      expect(app.run("cat .profile.d/WEB_CONCURRENCY.sh").strip).to be_empty
      expect(app.run("echo $WEB_CONCURRENCY").strip).to be_empty
      expect(app.run("echo $WEB_CONCURRENCY", :heroku => {:env => "WEB_CONCURRENCY=0"}).strip).to eq("0")
    end
  end
end
