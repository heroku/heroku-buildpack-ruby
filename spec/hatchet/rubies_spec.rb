require_relative '../spec_helper'

describe "Ruby Versions on cedar-14" do
  it "should allow patchlevels" do
    app = Hatchet::Runner.new('mri_193_p547', stack: "cedar-14")
    app.setup!
    app.deploy do |app|
      version = '1.9.3p547'
      expect(app.output).to match("ruby-1.9.3-p547")
      expect(app.run('ruby -v')).to match(version)
    end
  end

  it "should deploy ruby 1.9.2 properly" do
    app = Hatchet::Runner.new('mri_192', stack: "cedar-14")
    app.setup!
    app.deploy do |app|
      version = '1.9.2'
      expect(app.output).to match(version)
      expect(app.run('ruby -v')).to match(version)
    end
  end

  it "should deploy ruby 1.9.3 properly" do
    app = Hatchet::Runner.new('mri_193', stack: "cedar-14")
    app.setup!
    app.deploy do |app|
      version = '1.9.3'
      expect(app.output).to match(version)
      expect(app.run('ruby -v')).to match(version)
    end
  end

  it "should deploy ruby 2.0.0 properly" do
    app = Hatchet::Runner.new('mri_200', stack: "cedar-14")
    app.setup!
    app.deploy do |app|
      version = '2.0.0'
      expect(app.output).to match(version)
      expect(app.run('ruby -v')).to match(version)

      expect(app.output).to match("devcenter.heroku.com/articles/ruby-default-web-server")
    end
  end

  it "should deploy jdk 8 on cedar-14 by default" do
    app = Hatchet::Runner.new("ruby_193_jruby_1_7_27", stack: "heroku-18")
    app.setup!
    app.deploy do |app|
      expect(app.output).to match("Installing JVM: openjdk-8")
      expect(app.output).to match("JRUBY_OPTS is:  -Xcompile.invokedynamic=false")
      expect(app.output).not_to include("OpenJDK 64-Bit Server VM warning")

      run!('git commit -am "redeploy" --allow-empty')
      app.set_config("JRUBY_BUILD_OPTS" => "--dev")
      app.push!
      expect(app.output).to match("JRUBY_OPTS is:  --dev")

      expect(app.run("ls vendor/jvm/jre/lib/ext")).to match("pgconfig.jar")
    end
  end

  it "should deploy jruby 1.7.16.1 (jdk 7) properly on cedar-14 with sys props file" do
    app = Hatchet::Runner.new("ruby_193_jruby_17161_jdk7", stack: "cedar-14")
    app.setup!
    app.deploy do |app|
      expect(app.output).to match("Installing JVM: openjdk-7")
      expect(app.output).not_to include("OpenJDK 64-Bit Server VM warning")
    end
  end

  it "should deploy jruby with the naether gem" do
    app = Hatchet::Runner.new("jruby_naether", stack: DEFAULT_STACK)
    app.setup!
    app.deploy do |app|
      expect(app.output).to match("Installing naether")
      expect(app.output).not_to include("An error occurred while installing naether")
    end
  end
end


describe "Upgrading ruby apps" do
  it "works when changing from default version" do
    app = Hatchet::Runner.new("default_ruby", stack: DEFAULT_STACK)
    app.setup!
    app.deploy do |app|
      expect(app.run("env | grep MALLOC_ARENA_MAX")).to match("MALLOC_ARENA_MAX=2")

      run!(%Q{echo "ruby '2.5.1'" >> Gemfile})
      run!("git add -A; git commit -m update-ruby")
      app.push!
      expect(app.output).to match("2.5.1")
      expect(app.run("ruby -v")).to match("2.5.1")
      expect(app.output).to match("Ruby version change detected")
    end
  end
end
