require "fileutils"
require "tmpdir"

S3_BUCKET_NAME  = "language-pack-ruby"

def s3_tools_dir
  File.expand_path("../support/s3", __FILE__)
end

def s3_upload(tmpdir, name)
  sh("#{s3_tools_dir}/s3 put #{S3_BUCKET_NAME} #{name}.tgz #{tmpdir}/#{name}.tgz")
end

def vendor_plugin(git_url)
  name = File.basename(git_url, File.extname(git_url))
  Dir.mktmpdir("#{name}-") do |tmpdir|
    FileUtils.rm_rf("#{tmpdir}/*")

    Dir.chdir(tmpdir) do
      sh "git clone #{git_url} ."
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
        sh("gem install #{gem} --version #{version} --no-ri --no-rdoc")
        sh("tar czvf #{tmpdir}/#{name}.tgz *")
        s3_upload(tmpdir, name)
      end
    end
  end
end

desc "update plugins"
task "plugins:update" do
  vendor_plugin "http://github.com/ddollar/rails_log_stdout.git"
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

      sh "curl http://pyyaml.org/download/libyaml/yaml-#{version}.tar.gz -s -o - | tar vzxf -"
      sh "vulcan build -v -o #{name}.tgz --source yaml-#{version} --command=\"env CFLAGS=-fPIC ./configure --enable-static --disable-shared --prefix=/app/vendor/yaml-#{version} && make && make install\""
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
      sh "vulcan build -v -o #{name}.tgz --source node-v#{version} --command=\"./configure --prefix #{prefix} && make install && mv #{prefix}/bin/node #{prefix}/. && rm -rf #{prefix}/include && rm -rf #{prefix}/lib && rm -rf #{prefix}/share && rm -rf #{prefix}/bin\""
      s3_upload(tmpdir, name)
    end
  end
end
