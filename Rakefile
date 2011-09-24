require "fileutils"
require "tmpdir"

def s3_tools_dir
  File.expand_path("../support/s3", __FILE__)
end

def vendor_plugin(git_url)
  name = File.basename(git_url, File.extname(git_url))
  Dir.mktmpdir("#{name}-") do |tmpdir|
    FileUtils.rm_rf("#{tmpdir}/*")

    Dir.chdir(tmpdir) do
      sh "git clone #{git_url} ."
      FileUtils.rm_rf("#{name}/.git")
      sh("tar czvf #{tmpdir}/#{name}.tgz *")
      sh("#{s3_tools_dir}/s3 put language-pack-ruby #{name}.tgz #{tmpdir}/#{name}.tgz")
    end
  end
end

def gem_base
  File.expand_path("../vendor/gems", __FILE__)
end

def in_gem_env(&block)
  old_gem_home = ENV['GEM_HOME']
  old_gem_path = ENV['GEM_PATH']
  ENV['GEM_HOME'] = ENV['GEM_PATH'] = gem_base.to_s

  yield

  ENV['GEM_HOME'] = old_gem_home
  ENV['GEM_PATH'] = old_gem_path
end

def install_gem(gem, version)
  in_gem_env do
    cmd = "gem install #{gem} --version #{version} --no-ri --no-rdoc"
    puts(cmd)
    system(cmd)
  end
end

def uninstall_gem(gem)
  in_gem_env do
    cmd = "gem uninstall #{gem}"
    puts(cmd)
    system(cmd)
  end
end

def gem_detected?(gem)
  output = ''
  in_gem_env do
    output = `gem list #{gem}`
  end

  output.split("\n").each do |line|
    md = /^([\S]+)/.match(line)
    return true if md && md[1] == gem
  end

  false
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

  uninstall_gem(gem) if gem_detected?(gem)
  install_gem(gem, version)
end

desc "update libyaml"
task "libyaml:update" do
  sh "curl -o yaml.tgz http://libyaml-compiler.herokuapp.com/yaml.tgz"
  sh "git rm -rf vendor/yaml-*" if Dir['vendor/yaml-*'].any?
  sh "cd vendor && tar -zxvf ../yaml.tgz"
  sh "git add vendor/yaml-*"
  sh "rm yaml.tgz" if File.exists?("yaml.tgz")
end
