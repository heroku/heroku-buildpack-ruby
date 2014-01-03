require_relative 'spec_helper'

describe "Ruby Versions" do
  it "should deploy ruby 1.8.7 properly" do
    Hatchet::Runner.new("mri_187").deploy do |app|
      version = '1.8.7'
      expect(app.output).to match(version)
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
    end
  end

  it "should deploy jruby 1.7.3 (legacy jdk) properly" do
    Hatchet::AnvilApp.new("ruby_193_jruby_173").deploy do |app|
      expect(app.output).to match("Installing JVM: openjdk1.7.0_25")
      expect(app.output).to match("ruby-1.9.3-jruby-1.7.3")
      expect(app.output).not_to include("OpenJDK 64-Bit Server VM warning")
      expect(app.run('ruby -v')).to match("jruby 1.7.3")
    end
  end

  it "should deploy jruby 1.7.6 (latest jdk) properly" do
    Hatchet::AnvilApp.new("ruby_193_jruby_176").deploy do |app|
      expect(app.output).to match("Installing JVM: openjdk7-latest")
      expect(app.output).to match("ruby-1.9.3-jruby-1.7.6")
      expect(app.output).not_to include("OpenJDK 64-Bit Server VM warning")
      expect(app.run('ruby -v')).to match("jruby 1.7.6")
    end
  end
end
