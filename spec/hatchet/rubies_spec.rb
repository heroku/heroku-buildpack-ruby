require_relative '../spec_helper'

describe "Ruby Versions on cedar-14" do
  it "should deploy jruby 1.7.16.1 (jdk 7) properly on cedar-14 with sys props file" do
    pending("Port this to a more recent stack")

    app = Hatchet::Runner.new("ruby_193_jruby_17161_jdk7", stack: "cedar-14")
    app.deploy do |app|
      expect(app.output).to match("Installing JVM: openjdk-7")
      expect(app.output).not_to include("OpenJDK 64-Bit Server VM warning")
    end
  end
end

describe "Ruby versions" do
  it "should deploy jdk on heroku-20" do
    Hatchet::Runner.new("default_ruby", stack: "heroku-20").tap do |app|
      app.before_deploy do |app|
        Pathname("Gemfile.lock").write(<<~EOM)
         GEM
           remote: https://rubygems.org/
           specs:
             rack (2.2.2)
             rake (13.0.1)

         PLATFORMS
           java

         DEPENDENCIES
           rack
           rake


         RUBY VERSION
            ruby 2.5.7p0 (jruby 9.2.13.0)
        EOM

        Pathname("Rakefile").write(<<~'EOM')
          task "assets:precompile" do
            puts "JRUBY_OPTS is: #{ENV['JRUBY_OPTS']}"
          end
        EOM
      end

      app.deploy do
        expect(app.output).to match("JRUBY_OPTS is: -Xcompile.invokedynamic=false")

        app.set_config("JRUBY_BUILD_OPTS" => "--dev")
        app.commit!
        app.push!
        expect(app.output).to match("JRUBY_OPTS is: --dev")

        expect(app.run("ls .jdk/jre/lib/ext/")).to match("pgconfig.jar")
      end
    end
  end

  it "should deploy jruby with the naether gem" do
    app = Hatchet::Runner.new("jruby_naether", stack: DEFAULT_STACK)
    app.deploy do |app|
      expect(app.output).to match("Installing naether")
      expect(app.output).not_to include("An error occurred while installing naether")
    end
  end
end

describe "Upgrading ruby apps" do
  it "works when changing from default version" do
    app = Hatchet::Runner.new("default_ruby", stack: DEFAULT_STACK)
    app.deploy do |app|
      expect(app.run("env | grep MALLOC_ARENA_MAX")).to match("MALLOC_ARENA_MAX=2")
      expect(app.run("env | grep DISABLE_SPRING")).to match("DISABLE_SPRING=1")

      run!(%Q{echo "ruby '2.5.1'" >> Gemfile})
      run!("git add -A; git commit -m update-ruby")
      app.push!
      expect(app.output).to match("2.5.1")
      expect(app.run("ruby -v")).to match("2.5.1")
      expect(app.output).to match("Ruby version change detected")
    end
  end
end
