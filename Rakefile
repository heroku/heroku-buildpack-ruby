require "fileutils"
require "tmpdir"
require 'hatchet/tasks'

S3_BUCKET_NAME  = "heroku-buildpack-ruby"
VENDOR_URL      = "https://s3.amazonaws.com/#{S3_BUCKET_NAME}"

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

def install_gem(gem, version)
  name = "#{gem}-#{version}"
  Dir.mktmpdir("#{gem}-#{version}") do |tmpdir|
    Dir.chdir(tmpdir) do |dir|
      FileUtils.rm_rf("#{tmpdir}/*")

      in_gem_env(tmpdir) do
        sh("unset RUBYOPT; gem install #{gem} --version #{version} --no-ri --no-rdoc --env-shebang")
        sh("rm #{gem}-#{version}.gem")
        sh("rm -rf cache/#{gem}-#{version}.gem")
        sh("tar czvf #{tmpdir}/#{name}.tgz *")
        s3_upload(tmpdir, name)
      end
    end
  end
end

def build_ruby_command(name, output, prefix, usr_dir, tmpdir, rubygems = nil)
  vulcan_prefix = "/app/vendor/#{output}"
  build_command = [
    # need to move libyaml/libffi to dirs we can see
    "mv #{usr_dir} /tmp",
    "./configure --enable-load-relative --disable-install-doc --prefix #{prefix}",
    "env CPATH=/tmp/#{usr_dir}/include:\\$CPATH CPPATH=/tmp/#{usr_dir}/include:\\$CPPATH LIBRARY_PATH=/tmp/#{usr_dir}/lib:\\$LIBRARY_PATH make",
    "make install"
  ]
  build_command << "#{prefix}/bin/ruby /tmp/#{usr_dir}/rubygems-#{rubygems}/setup.rb" if rubygems
  build_command << "mv #{prefix} /app/vendor/#{output}" if prefix != "/app/vendor/#{output}"
  build_command = build_command.join(" && ")

  sh "vulcan build -v -o #{output}.tgz --prefix #{vulcan_prefix} --source #{name} --command=\"#{build_command}\""
  s3_upload(tmpdir, output)
end

def build_rbx_command(name, output, prefix, usr_dir, tmpdir, ruby_version)
  build_command = [
    # need to move libyaml/libffi to dirs we can see
    "mv usr /tmp",
    "ls /tmp/#{usr_dir}",
    "./configure --prefix #{prefix} --enable-version=#{ruby_version} --default-version=#{ruby_version} --with-include-dir=/tmp/#{usr_dir}/include --with-lib-dir=/tmp/#{usr_dir}/lib",
    "rake install"
  ]
  # build_command << "mv #{prefix} /app/vendor/#{name}" if name != output
  build_command = build_command.join(" && ")

  sh "vulcan build -v -o #{output}.tgz --source #{name} --prefix #{prefix} --command=\"#{build_command}\""
  s3_upload(tmpdir, output)
end

desc "update plugins"
task "plugins:update" do
  vendor_plugin "http://github.com/heroku/rails_log_stdout.git", "legacy"
  vendor_plugin "http://github.com/pedro/rails3_serve_static_assets.git"
  vendor_plugin "http://github.com/hone/rails31_enable_runtime_asset_compilation.git"
end

desc "install vendored gem"
task "gem:install", :gem, :version do |t, args|
  gem     = args[:gem]
  version = args[:version]

  install_gem(gem, version)
end

desc "install libyaml"
task "libyaml:install", :version do |t, args|
  version = args[:version]
  name = "libyaml-#{version}"
  Dir.mktmpdir("libyaml-") do |tmpdir|
    Dir.chdir(tmpdir) do |dir|
      FileUtils.rm_rf("#{tmpdir}/*")
      prefix = "/app/vendor/yaml-#{version}"

      sh "curl http://pyyaml.org/download/libyaml/yaml-#{version}.tar.gz -s -o - | tar vzxf -"

      build_command = [
        "env CFLAGS=-fPIC ./configure --enable-static --disable-shared --prefix=#{prefix}",
        "make",
        "make install"
      ].join(" && ")

      sh "vulcan build -v -o #{name}.tgz --source yaml-#{version} --prefix=#{prefix} --command=\"#{build_command}\""
      s3_upload(tmpdir, name)
    end
  end
end

desc "install node"
task "node:install", :version do |t, args|
  version = args[:version]
  name    = "node-#{version}"
  prefix  = "/app/vendor/node-v#{version}"
  Dir.mktmpdir("node-") do |tmpdir|
    Dir.chdir(tmpdir) do |dir|
      FileUtils.rm_rf("#{tmpdir}/*")

      sh "curl http://nodejs.org/dist/node-v#{version}.tar.gz -s -o - | tar vzxf -"

      build_command = [
        "./configure --prefix #{prefix}",
        "make install",
        "mv #{prefix}/bin/node #{prefix}/.",
        "rm -rf #{prefix}/include",
        "rm -rf #{prefix}/lib",
        "rm -rf #{prefix}/share",
        "rm -rf #{prefix}/bin"
      ].join(" && ")

      sh "vulcan build -v -o #{name}.tgz --source node-v#{version} --command=\"#{build_command}\" --prefix=\"#{prefix}\""
      s3_upload(tmpdir, name)
    end
  end
end

desc "install ruby"
task "ruby:install", :version do |t, args|
  full_version   = args[:version]
  full_name      = "ruby-#{full_version}"
  version        = full_version.split('-').first
  name           = "ruby-#{version}"
  usr_dir        = "usr"
  rubygems       = nil
  Dir.mktmpdir("ruby-") do |tmpdir|
    Dir.chdir(tmpdir) do |dir|
      FileUtils.rm_rf("#{tmpdir}/*")

      major_ruby = version.match(/\d\.\d/)[0]
      rubygems   = "1.8.24" if major_ruby == "1.8"
      sh "curl http://ftp.ruby-lang.org/pub/ruby/#{major_ruby}/#{full_name}.tar.gz -s -o - | tar zxf -"
      FileUtils.mkdir_p("#{full_name}/#{usr_dir}")
      Dir.chdir("#{full_name}/#{usr_dir}") do
        sh "curl #{VENDOR_URL}/libyaml-0.1.4.tgz -s -o - | tar zxf -"
        sh "curl #{VENDOR_URL}/libffi-3.0.10.tgz -s -o - | tar zxf -"
        sh "curl http://production.cf.rubygems.org/rubygems/rubygems-#{rubygems}.tgz -s -o - | tar xzf -" if major_ruby == "1.8"
      end

      # runtime ruby
      prefix  = "/app/vendor/#{name}"
      build_ruby_command(full_name, name, prefix, usr_dir, tmpdir, rubygems)

      # build ruby
      if major_ruby == "1.8"
        output  = "ruby-build-#{version}"
        prefix  = "/tmp/ruby-#{version}"
        build_ruby_command(full_name, output, prefix, usr_dir, tmpdir, rubygems)
      end
    end
  end
end

desc "install rbx"
task "rbx:install", :version do |t, args|
  version = args[:version]
  name    = "rubinius-#{version}"
  output  = "rbx-#{version}"
  prefix  = "/app/vendor/#{output}"

  Dir.mktmpdir("rbx-") do |tmpdir|
    Dir.chdir(tmpdir) do |dir|
      FileUtils.rm_rf("#{tmpdir}/*")

      sh "curl http://asset.rubini.us/#{name}.tar.gz -s -o - | tar vzxf -"
      build_command = [
        "./configure --prefix #{prefix}",
        "rake install"
      ].join(" && ")

      sh "vulcan build -v -o #{output}.tgz --source #{name} --prefix #{prefix} --command=\"#{build_command}\""
      s3_upload(tmpdir, output)
    end
  end
end

desc "install rbx 2.0.0dev"
task "rbx2dev:install", :version, :ruby_version do |t, args|
  version      = args[:version]
  ruby_version = args[:ruby_version]
  source       = "rubinius-#{version}"
  name         = "rubinius-2.0.0dev"
  output       = "rbx-#{version}-#{ruby_version}"
  usr_dir      = "usr"

  Dir.mktmpdir("rbx-") do |tmpdir|
    Dir.chdir(tmpdir) do |dir|
      FileUtils.rm_rf("#{tmpdir}/*")

      sh "curl http://asset.rubini.us/#{source}.tar.gz -s -o - | tar vzxf -"
      FileUtils.mkdir_p("#{name}/#{usr_dir}")
      Dir.chdir("#{name}/#{usr_dir}") do
        sh "curl #{VENDOR_URL}/libyaml-0.1.4.tgz -s -o - | tar vzxf -"
        sh "curl #{VENDOR_URL}/libffi-3.0.10.tgz -s -o - | tar vzxf -"
      end

      prefix = "/app/vendor/#{output}"
      build_rbx_command(name, output, prefix, usr_dir, tmpdir, ruby_version)

      # rbx build
      prefix  = "/tmp/#{output}"
      output  = "rbx-build-#{version}-#{ruby_version}"
      build_rbx_command(name, output, prefix, usr_dir, tmpdir, ruby_version)
    end
  end
end

desc "install jruby"
task "jruby:install", :version, :ruby_version do |t, args|
  version      = args[:version]
  ruby_version = args[:ruby_version]
  name         = "jruby-src-#{version}"
  src_folder   = "jruby-#{version}"
  output       = "ruby-#{ruby_version}-jruby-#{version}"
  launcher     = "launcher"

  Dir.mktmpdir("jruby-") do |tmpdir|
    Dir.chdir(tmpdir) do
      sh "curl http://jruby.org.s3.amazonaws.com/downloads/#{version}/#{name}.tar.gz -s -o - | tar vzxf -"
      sh "rm -rf test"
      Dir.chdir(src_folder) do
        sh "curl http://www.nic.funet.fi/pub/mirrors/apache.org/ant/binaries/apache-ant-1.8.4-bin.tar.gz -s -o - | tar vxzf -"
        sh "rm -rf manual"
      end
      Dir.chdir("#{src_folder}/bin") do
        sh "curl #{VENDOR_URL}/jruby-launcher-1.0.12-java.tgz -s -o - | tar vzxf -"
      end

      major, minor, patch = ruby_version.split('.')

      build_command = [
        "apache-ant-1.8.4/bin/ant -Djruby.default.ruby.version=#{major}.#{minor}",
        "rm bin/*.bat",
        "rm bin/*.dll",
        "rm bin/*.exe",
        "ln -s jruby bin/ruby",
        "mkdir -p /app/vendor/#{output}",
        "mv bin /app/vendor/#{output}",
        "mv lib /app/vendor/#{output}"
      ]
      build_command = build_command.join(" && ")
      sh "vulcan build -v -o #{output}.tgz --prefix /app/vendor/#{output} --source #{src_folder} --command=\"#{build_command}\""

      s3_upload(tmpdir, output)
    end
  end
end

desc "build the jruby-launcher"
task "jruby:launcher", :version do |t, args|
  version = args[:version]
  name    = "jruby-launcher-#{version}-java"
  prefix  = "/tmp/jruby-launcher"

  Dir.mktmpdir("jruby-launcher-") do |tmpdir|
    Dir.chdir(tmpdir) do
      sh "gem fetch jruby-launcher --platform java --version #{version}"
      sh "gem unpack jruby-launcher-#{version}-java.gem"

      build_command = [
        "make",
        "mkdir -p #{prefix}",
        "cp jruby #{prefix}"
      ].join(" && ")

      sh "vulcan build -v -o #{name}.tgz --source #{name} --prefix #{prefix} --command=\"#{build_command}\""
      s3_upload(tmpdir, name)
    end
  end

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

desc "install libffi"
task "libffi:install", :version do |t, args|
  version = args[:version]
  name    = "libffi-#{version}"
  prefix  = "/app/vendor/#{name}"
  Dir.mktmpdir("libffi-") do |tmpdir|
    Dir.chdir(tmpdir) do |dir|
      FileUtils.rm_rf("#{tmpdir}/*")

      sh "curl ftp://sourceware.org/pub/libffi/libffi-#{version}.tar.gz -s -o - | tar vzxf -"

      build_command = [
        "env CFLAGS=-fPIC ./configure --enable-static --disable-shared --prefix=#{prefix}",
        "make",
        "make install",
        "mv #{prefix}/lib/#{name}/include #{prefix}",
        "rm -rf #{prefix}/lib/#{name}"
      ].join(" && ")

      sh "vulcan build -v -o #{name}.tgz --source #{name} --prefix=#{prefix} --command=\"#{build_command}\""
      s3_upload(tmpdir, name)
    end
  end
end

namespace :buildpack do
  require 'netrc'
  require 'excon'
  require 'json'
  require 'time'
  require 'cgi'
  require 'git'
  require 'fileutils'
  require 'digest/md5'
  require 'securerandom'

  def connection
    @connection ||= begin
      user, password = Netrc.read["api.heroku.com"]
      Excon.new("https://#{CGI.escape(user)}:#{password}@buildkits.herokuapp.com")
    end
  end

  def latest_release
    @latest_release ||= begin
      buildpack_name = "heroku/ruby"
      response = connection.get(path: "buildpacks/#{buildpack_name}/revisions")
      releases = JSON.parse(response.body)

      # {
      #   "tar_link": "https://codon-buildpacks.s3.amazonaws.com/buildpacks/heroku/ruby-v84.tgz",
      #   "created_at": "2013-11-06T18:55:04Z",
      #   "published_by": "richard@heroku.com",
      #   "id": 84
      #  }
      releases.map! do |a|
        a["created_at"] = Time.parse(a["created_at"])
        a
      end.sort! { |a,b| b["created_at"] <=> a["created_at"] }
      releases.first
    end
  end

  def new_version
    @new_version ||= "v#{latest_release["id"] + 1}"
  end

  desc "increment buildpack version"
  task :increment do
    version_file = './lib/language_pack/version'
    require './lib/language_pack'
    require version_file

    if LanguagePack::Base::BUILDPACK_VERSION != new_version
      git     = Git.open(".")
      stashes = nil

      if git.status.changed
        stashes = Git::Stashes.new(git)
        stashes.save("WIP")
      end

      File.open("#{version_file}.rb", 'w') do |file|
      file.puts <<-FILE
require "language_pack/base"

# This file is automatically generated by rake
module LanguagePack
  class LanguagePack::Base
    BUILDPACK_VERSION = "#{new_version}"
  end
end
FILE
      end

      git.add "#{version_file}.rb"
      git.commit "bump to #{new_version}"

      stashes.pop if stashes
    else
      puts "Already on #{new_version}"
    end
  end

  def changelog_entry?
    File.read("./CHANGELOG.md").split("\n").any? {|line| line.match(/^## #{new_version}/) }
  end

  desc "check if there's a changelog for the new version"
  task :changelog do
    if changelog_entry?
      puts "Changelog for #{new_version} exists"
    else
      puts "Please add a changelog entry for #{new_version}"
    end
  end

  desc "stage a tarball of the buildpack"
  task :stage do
    Dir.mktmpdir("heroku-buildpack-ruby") do |tmpdir|
      Git.clone(File.expand_path("."), 'heroku-buildpack-ruby', path: tmpdir)
      Dir.chdir(tmpdir) do |dir|
        streamer = lambda do |chunk, remaining_bytes, total_bytes|
          File.open("ruby.tgz", "w") {|file| file.print(chunk) }
        end
        Excon.get(latest_release["tar_link"], :response_block => streamer)
        Dir.chdir("heroku-buildpack-ruby") do |dir|
          sh "tar xzf ../ruby.tgz .env"
          sh "tar czf ../buildpack.tgz * .env"
        end

        @digest = Digest::MD5.hexdigest(File.read("buildpack.tgz"))
      end

      filename = "buildpacks/#{@digest}.tgz"
      puts "Writing to #{filename}"
      FileUtils.mkdir_p("buildpacks/")
      FileUtils.cp("#{tmpdir}/buildpack.tgz", filename)
      FileUtils.cp("#{tmpdir}/buildpack.tgz", "buildpacks/buildpack.tgz")
    end
  end

  def multipart_form_data(buildpack_file_path)
    body = ''
    boundary = SecureRandom.hex(4)
    data = File.open(buildpack_file_path)

    data.binmode if data.respond_to?(:binmode)
    data.pos = 0 if data.respond_to?(:pos=)

    body << "--#{boundary}" << Excon::CR_NL
    body << %{Content-Disposition: form-data; name="buildpack"; filename="#{File.basename(buildpack_file_path)}"} << Excon::CR_NL
    body << 'Content-Type: application/x-gtar' << Excon::CR_NL
    body << Excon::CR_NL
    body << File.read(buildpack_file_path)
    body << Excon::CR_NL
    body << "--#{boundary}--" << Excon::CR_NL

    {
      :headers => { 'Content-Type' => %{multipart/form-data; boundary="#{boundary}"} },
      :body => body
    }
  end

  desc "publish buildpack"
  task :publish do
    buildpack_name = "heroku/ruby"
    puts "Publishing #{buildpack_name} buildpack"
    resp = connection.post(multipart_form_data("buildpacks/buildpack.tgz").merge(path: "/buildpacks/#{buildpack_name}"))
    puts resp.status
    puts resp.body
  end

  desc "tag a release"
  task :tag do
    git = Git.open(".")
    git.add_tag(new_version)
    puts "Created tag #{new_version}"

    remote = git.remotes.detect {|remote| remote.url.match(%r{heroku/heroku-buildpack-ruby.git$}) }
    puts "Pushing tag to remote #{remote}"
    git.push(remote, nil, true)
  end

  desc "release a new version of the buildpack"
  task :release do
    Rake::Task["buildpack:increment"].invoke
    raise "Please add a changelog entry for #{new_version}" unless changelog_entry?
    Rake::Task["buildpack:stage"].invoke
    Rake::Task["buildpack:publish"].invoke
    Rake::Task["buildpack:tag"].invoke
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
