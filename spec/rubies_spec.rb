require_relative 'spec_helper'

describe "Ruby Versions" do
  it "should allow patchlevels" do
    Hatchet::Runner.new("mri_193_p547").deploy do |app|
      version = '1.9.3p547'
      expect(app.output).to match("ruby-1.9.3-p547")
      expect(app.run('ruby -v')).to match(version)
    end
  end

  it "should deploy ruby 1.9.2 properly" do
    Hatchet::Runner.new("mri_192").deploy do |app|
      version = '1.9.2'
      expect(app.output).to match(version)
      expect(app.run('ruby -v')).to match(version)
    end
  end

  it "should deploy ruby 1.9.2 properly (git)" do
    Hatchet::GitApp.new("mri_192", buildpack: git_repo).deploy do |app|
      version = '1.9.2'
      expect(app.output).to match(version)
      expect(app.run('ruby -v')).to match(version)
    end
  end

  it "should deploy ruby 1.9.3 properly" do
    Hatchet::Runner.new("mri_193").deploy do |app|
      version = '1.9.3'
      expect(app.output).to match(version)
      expect(app.run('ruby -v')).to match(version)
    end
  end

  it "should deploy ruby 2.0.0 properly" do
    Hatchet::Runner.new("mri_200").deploy do |app|
      version = '2.0.0'
      expect(app.output).to match(version)
      expect(app.run('ruby -v')).to match(version)

      expect(app.output).to match("devcenter.heroku.com/articles/ruby-default-web-server")
    end
  end

  it "should deploy jdk 8 on cedar-14 by default" do
    app = Hatchet::Runner.new("ruby_193_jruby_17161")
    app.setup!
    app.heroku.put_stack(app.name, 'cedar-14')

    app.deploy do |app|
      expect(app.output).to match("Installing JVM: openjdk-8")
      expect(app.output).to match("JRUBY_OPTS is:  -Xcompile.invokedynamic=false")
      expect(app.output).not_to include("OpenJDK 64-Bit Server VM warning")

      `git commit -am "redeploy" --allow-empty`
      app.set_config("JRUBY_BUILD_OPTS" => "--dev")
      app.push!
      expect(app.output).to match("JRUBY_OPTS is:  --dev")
    end
  end

  it "should deploy jruby 1.7.16.1 (jdk 7) properly on cedar-14 with sys props file" do
    app = Hatchet::Runner.new("ruby_193_jruby_17161_jdk7")
    app.setup!
    app.heroku.put_stack(app.name, 'cedar-14')

    app.deploy do |app|
      expect(app.output).to match("Installing JVM: openjdk-7")
      expect(app.output).not_to include("OpenJDK 64-Bit Server VM warning")
    end
  end
end
