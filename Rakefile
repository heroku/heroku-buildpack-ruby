# CAREFUL! Changes made to this file aren't tested
#
# If you need new functionality, consider putting it in lib/rake
# and also adding tests, then calling that code from here
#
require "fileutils"
require "tmpdir"
require 'hatchet/tasks'
require_relative 'lib/rake/deploy_check'

namespace :buildpack do
  desc "prepares the next version of the buildpack for release"
  task :prepare do
    puts("Use https://github.com/heroku/heroku-buildpack-ruby/actions/workflows/prepare-release.yml")
  end

  desc "releases the next version of the buildpack"
  task :release do
    puts "Checking login state"
    sh("heroku whoami") do |out, status|
      if status.success?
        puts "Success"
      else
        raise "Ensure login works: `heroku login`"
      end
    end

    deploy = DeployCheck.new(github: "heroku/heroku-buildpack-ruby")
    puts "Attempting to deploy #{deploy.next_version}, overwrite with RELEASE_VERSION env var"
    deploy.check!
    if deploy.push_tag?
      sh("git tag -f #{deploy.next_version}") do |out, status|
        raise "Could not `git tag -f #{deploy.next_version}`: #{out}" unless status.success?
      end
      sh("git push --tags") do |out, status|
        raise "Could not `git push --tags`: #{out}" unless status.success?
      end
    end

    command = "heroku buildpacks:publish heroku/ruby #{deploy.next_version}"
    puts "Releasing to heroku: `#{command}`"
    exec(command)
  end
end

begin
  require 'rspec/core/rake_task'

  desc "Run specs"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = %w(-fd --color)
    #t.ruby_opts  = %w(-w)
  end
  task :default => :spec
rescue LoadError => e
end
