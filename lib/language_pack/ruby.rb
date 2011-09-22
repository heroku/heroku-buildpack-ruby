$: << File.expand_path(Dir["#{File.join(File.dirname(__FILE__), "../..", "vendor/gems/gems/")}/bundler*/lib"].first)
require "language_pack"
require "language_pack/base"
require "bundler"

class LanguagePack::Ruby < LanguagePack::Base
  YAML_PATH = "yaml-0.1.4"

  def self.use?
    File.exist?("Gemfile")
  end

  def name
    "Ruby"
  end

  def default_addons
    []
  end

  def default_config_vars
    {
      "LANG"     => "en_US.UTF-8",
      "PATH"     => default_path,
      "GEM_PATH" => slug_vendor_base,
    }
  end

  def default_process_types
    {
      "rake"    => "bundle exec rake",
      "console" => "bundle exec irb"
    }
  end

  def compile
    Dir.chdir(build_path)
    setup_language_pack_environment
    allow_git do
      build_bundler
      create_database_yml
      install_binaries
      run_compile_hook
    end
  end

private

  def default_path
    "#{slug_vendor_base}/bin:/usr/local/bin:/usr/bin:/bin:bin"
  end

  def language_pack_gems
    File.expand_path("../../../vendor/gems", __FILE__)
  end

  def slug_vendor_base
    "vendor/bundle/ruby/1.9.1"
  end

  def setup_language_pack_environment
    default_config_vars.each do |key, value|
      ENV[key] ||= value
    end
    ENV["GEM_HOME"] = slug_vendor_base
    ENV["PATH"] = default_config_vars["PATH"]
  end

  def install_language_pack_gems
    FileUtils.mkdir_p(File.dirname(slug_vendor_base))
    FileUtils.cp_r("#{language_pack_gems}/.", slug_vendor_base, :preserve => true)
  end

  def binaries
    []
  end

  def install_binaries
    FileUtils.mkdir_p "bin"
    binaries.each {|binary| install_binary(binary) }
    Dir["bin/*"].each {|path| run("chmod +x #{path}") }
  end

  def install_binary(path)
    FileUtils.cp File.join(binary_root, path), File.join('bin', File.basename(path))
  end

  def uninstall_binary(path)
    FileUtils.rm File.join('bin', File.basename(path)), :force => true
  end

  def binary_root
    File.expand_path("../../../vendor", __FILE__)
  end

  def build_bundler
    yaml_include   = File.expand_path("#{binary_root}/#{YAML_PATH}/include")
    yaml_lib       = File.expand_path("#{binary_root}/#{YAML_PATH}/lib")
    env_vars       = "env CPATH=#{yaml_include}:$CPATH CPPATH=#{yaml_include}:$CPPATH LIBRARY_PATH=#{yaml_lib}:$LIBRARY_PATH"
    bundle_command = "bundle install --without development:test --path vendor/bundle"

    unless File.exist?("Gemfile.lock")
      error "Gemfile.lock is required. Please run \"bundle install\" locally\nand commit your Gemfile.lock."
    end

    if has_windows_gemfile_lock?
      File.unlink("Gemfile.lock")
    else
      bundle_command += " --deployment"
      cache_load ".bundle"
    end

    cache_load "vendor/bundle"

    install_language_pack_gems

    version = run("bundle version").strip
    topic("Installing dependencies using #{version}")

    puts "Running: #{bundle_command}"
    pipe("#{env_vars} #{bundle_command} --no-clean 2>&1")

    if $?.success?
      puts "Cleaning up the bundler cache."
      run "bundle clean"
      cache_store ".bundle"
      cache_store "vendor/bundle"
    else
      error "Failed to install gems via Bundler."
    end
  end

  def create_database_yml
    return unless File.directory?("config")
    topic("Writing config/database.yml to read from DATABASE_URL")
    File.open("config/database.yml", "w") do |file|
      file.puts <<-DATABASE_YML
<%

require 'cgi'
require 'uri'

begin
  uri = URI.parse(ENV["DATABASE_URL"])
rescue URI::InvalidURIError
  raise "Invalid DATABASE_URL"
end

raise "No RACK_ENV or RAILS_ENV found" unless ENV["RAILS_ENV"] || ENV["RACK_ENV"]

def attribute(name, value)
  value ? "\#{name}: \#{value}" : ""
end

adapter = uri.scheme
adapter = "postgresql" if adapter == "postgres"

database = (uri.path || "").split("/")[1]

username = uri.user
password = uri.password

host = uri.host
port = uri.port

params = CGI.parse(uri.query || "")

%>

<%= ENV["RAILS_ENV"] || ENV["RACK_ENV"] %>:
  <%= attribute "adapter",  adapter %>
  <%= attribute "database", database %>
  <%= attribute "username", username %>
  <%= attribute "password", password %>
  <%= attribute "host",     host %>
  <%= attribute "port",     port %>

<% params.each do |key, value| %>
  <%= key %>: <%= value.first %>
<% end %>
      DATABASE_YML
    end
  end

  def run_compile_hook
    if rake_task_defined?("compile")
      topic "Running compile hook"
      pipe("bundle exec rake compile 2>&1")
      unless $?.success?
        error "Compile hook failed"
      end
    end
  end

  def has_windows_gemfile_lock?
    parser = Bundler::LockfileParser.new(File.read("Gemfile.lock"))
    parser.platforms.detect do |platform|
      /mingw|mswin/.match(platform.os) if platform.is_a?(Gem::Platform)
    end
  end

  def gem_is_bundled?(gem)
    @bundle_show ||= run("bundle show")
    @bundle_show.split("\n").detect { |line| line =~ / \* #{gem} / }
  end

  def rake_task_defined?(task)
    run("env PATH=$PATH bundle exec rake #{task} --dry-run") && $?.success?
  end

  def allow_git(&blk)
    git_dir = ENV.delete("GIT_DIR") # can mess with bundler
    blk.call
    ENV["GIT_DIR"] = git_dir
  end
end
