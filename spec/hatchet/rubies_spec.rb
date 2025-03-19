require_relative '../spec_helper'

describe "Ruby versions" do
  it "should deploy jdk on heroku-24" do
    Hatchet::Runner.new("default_ruby", stack: "heroku-24").tap do |app|
      app.before_deploy do |app|
        Pathname("Gemfile.lock").write(<<~EOM)
         GEM
           remote: https://rubygems.org/
           specs:
             rack (3.1.8)
             rake (13.2.1)
             webrick (1.9.1)

         PLATFORMS
           java

         DEPENDENCIES
           rack
           rake
           webrick

         RUBY VERSION
            ruby 3.1.4p0 (jruby 9.4.8.0)

         BUNDLED WITH
            2.5.23
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

        expect(app.run("ruby -v")).to match("jruby")
      end
    end
  end
end

describe "Upgrading ruby apps" do
  it "works when changing versions" do
    version = "3.3.1"
    expect(version).to_not eq(LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER)
    app = Hatchet::Runner.new("default_ruby", stack: DEFAULT_STACK)
    app.deploy do |app|
      # default version
      expect(app.run("env | grep MALLOC_ARENA_MAX")).to match("MALLOC_ARENA_MAX=2")
      expect(app.run("env | grep DISABLE_SPRING")).to match("DISABLE_SPRING=1")

      # Deploy again
      run!(%Q{echo "ruby '#{version}'" >> Gemfile})
      run!("git add -A; git commit -m update-ruby")
      app.push!
      expect(app.output).to match(version)
      expect(app.run("ruby -v")).to match(version)
      expect(app.output).to match("Ruby version change detected")
    end
  end
end
