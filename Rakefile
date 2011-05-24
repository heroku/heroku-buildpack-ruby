require "fileutils"

def plugin_base
  File.expand_path("../vendor/plugins", __FILE__)
end

def vendor_plugin(git_url)
  name = File.basename(git_url, File.extname(git_url))
  Dir.chdir(plugin_base) do
    FileUtils.rm_rf(name)
    sh "git clone #{git_url} #{name}"
    FileUtils.rm_rf("#{name}/.git")
  end
end

desc "update plugins"
task "plugins:update" do
  vendor_plugin "http://github.com/ddollar/rails_log_stdout.git"
  vendor_plugin "http://github.com/pedro/rails3_serve_static_assets.git"
end
