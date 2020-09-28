require "fileutils"
require "tmpdir"
require 'hatchet/tasks'
ENV["BUILDPACK_LOG_FILE"] ||= "tmp/buildpack.log"

S3_BUCKET_NAME  = "heroku-buildpack-ruby"

def s3_tools_dir
  File.expand_path("../support/s3", __FILE__)
end

def s3_upload(tmpdir, name)
  sh("#{s3_tools_dir}/s3 put #{S3_BUCKET_NAME} #{name}.tgz #{tmpdir}/#{name}.tgz")
end

def vendor_plugin(git_url, branch = nil)
  name = File.basename(git_url, File.extname(git_url))
  Dir.mktmpdir("#{name}-") do |tmpdir|
    FileUtils.rm_rf("#{tmpdir}/*")

    Dir.chdir(tmpdir) do
      sh "git clone #{git_url} ."
      sh "git checkout origin/#{branch}" if branch
      FileUtils.rm_rf("#{name}/.git")
      sh("tar czvf #{tmpdir}/#{name}.tgz *")
      s3_upload(tmpdir, name)
    end
  end
end

def in_gem_env(gem_home, &block)
  old_gem_home = ENV['GEM_HOME']
  old_gem_path = ENV['GEM_PATH']
  ENV['GEM_HOME'] = ENV['GEM_PATH'] = gem_home.to_s

  yield

  ENV['GEM_HOME'] = old_gem_home
  ENV['GEM_PATH'] = old_gem_path
end

def install_gem(gem_name, version)
  name = "#{gem_name}-#{version}"
  Dir.mktmpdir("#{gem_name}-#{version}") do |tmpdir|
    Dir.chdir(tmpdir) do |dir|
      FileUtils.rm_rf("#{tmpdir}/*")

      in_gem_env(tmpdir) do
        sh("unset RUBYOPT; gem install #{gem_name} --version #{version} --no-ri --no-rdoc --env-shebang")
        sh("rm #{gem_name}-#{version}.gem")
        sh("rm -rf cache/#{gem_name}-#{version}.gem")
        sh("tar czvf #{tmpdir}/#{name}.tgz *")
        s3_upload(tmpdir, name)
      end
    end
  end
end

namespace :deploy do

  task :buildpack
end

namespace :buildpack do
  task :check_unstaged do
    `git diff --quiet HEAD`
    raise "Must have all changes committed. There are unstaged commits locally" unless $?.success?
  end

  task :check_branch do
    out = `git rev-parse --abbrev-ref HEAD`.strip
    raise "Must be on main branch. Branch: #{out}" unless out == "main"
  end

  task :next_release_version do
    ENV["RELEASE_VERSION"] ||= begin
      string_tag_array = `git tag --list`.strip.each_line.map.select {|line| line.match?(/^v\d+$/) } # https://rubular.com/r/8eFB9r8nOVrM7H
      integer_tag_array = string_tag_array.map {|line| line.sub(/^v/, '').to_i }.sort # Ascending order
      last_version = integer_tag_array.last
      "v#{last_version.next}"
    end
    puts "Next buildpack release version: #{ENV["RELEASE_VERSION"]}"
  end

  task :check_changelog => [:next_release_version] do
    if !File.read("CHANGELOG.md").include?("## #{ENV['RELEASE_VERSION']}")
      raise "Expected CHANGELOG.md to include #{ENV['RELEASE_VERSION']} but it did not"
    end
  end

  task :check_synced_with_github do
    out = `git rev-parse HEAD`.strip
    raise "Could not get commit SHA via 'git rev-parse HEAD'. output: #{out}" unless $?.success?

  end

  task :release => [:next_release_version, :check_unstaged, :check_branch, :check_changelog, :check_synced_with_github] do
    # Check head is latest
    sh("git tag", version) do |out, status|
      raise "Could not `git tag #{version}: #{out}" unless status.success?
    end
    sh("git push --tags") do |out, status|
      raise "Could not `git push --tags" unless status.success?
    end
  end

  desc "stage a tarball of the buildpack, runs on github actions"
  task :tarball do

    Dir.mktmpdir("heroku-buildpack-ruby") do |tmpdir|

      sh "cp #{__dir__} #{tmpdir}/heroku-buildpack-ruby"

      Dir.chdir(tmpdir) do
        Dir.chdir("heroku-buildpack-ruby") do |buildpack_dir|
          $:.unshift File.expand_path("../lib", __FILE__)
          require "language_pack/installers/heroku_ruby_installer"
          require "language_pack/ruby_version"
          require "language_pack/version"

          %w(cedar-14 heroku-16 heroku-18).each do |stack|
            installer    = LanguagePack::Installers::HerokuRubyInstaller.new(stack)
            ruby_version = LanguagePack::RubyVersion.new("ruby-#{LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER}")
            installer.fetch_unpack(ruby_version, "vendor/ruby/#{stack}")
          end

          sh "tar czf ../buildpack.tgz *"
        end

        @digest = Digest::MD5.hexdigest(File.read("buildpack.tgz"))
      end


      filename = "buildpacks/heroku-buildpack-ruby-#{LanguagePack::Base::BUILDPACK_VERSION}.tgz"
      puts "Writing to #{filename}"

      FileUtils.mkdir_p("buildpacks/")
      FileUtils.cp("#{tmpdir}/buildpack.tgz", filename)
    end
  end
end

desc "update plugins"
task "plugins:update" do
  vendor_plugin "https://github.com/heroku/rails_log_stdout.git", "legacy"
  vendor_plugin "https://github.com/pedro/rails3_serve_static_assets.git"
  vendor_plugin "https://github.com/hone/rails31_enable_runtime_asset_compilation.git"
end

desc "install vendored gem"
task "gem:install", :gem, :version do |t, args|
  gem     = args[:gem]
  version = args[:version]

  install_gem(gem, version)
end

desc "generate ruby versions manifest"
task "ruby:manifest" do
  require 'rexml/document'
  require 'yaml'

  document = REXML::Document.new(`curl https://#{S3_BUCKET_NAME}.s3.amazonaws.com`)
  rubies   = document.elements.to_a("//Contents/Key").map {|node| node.text }.select {|text| text.match(/^(ruby|rbx|jruby)-\\\\d+\\\\.\\\\d+\\\\.\\\\d+(-p\\\\d+)?/) }

  Dir.mktmpdir("ruby_versions-") do |tmpdir|
    name = 'ruby_versions.yml'
    File.open(name, 'w') {|file| file.puts(rubies.to_yaml) }
    sh("#{s3_tools_dir}/s3 put #{S3_BUCKET_NAME} #{name} #{name}")
  end
end

begin
  require 'rspec/core/rake_task'

  desc "Run specs"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = %w(-fs --color)
    #t.ruby_opts  = %w(-w)
  end
  task :default => :spec
rescue LoadError => e
end
