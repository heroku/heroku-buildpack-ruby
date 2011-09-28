require "tmpdir"
require "language_pack"
require "language_pack/base"

# base Ruby Language Pack. This is for any base ruby app.
class LanguagePack::Ruby < LanguagePack::Base
  LIBYAML_VERSION  = "0.1.4"
  LIBYAML_PATH     = "libyaml-#{LIBYAML_VERSION}"
  BUNDLER_VERSION  = "1.1.pre.9"
  BUNDLER_GEM_PATH = "bundler-#{BUNDLER_VERSION}"

  # detects if this is a valid Ruby app
  # @return [Boolean] true if it's a Ruby app
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
      install_language_pack_gems
      build_bundler
      create_database_yml
      install_binaries
    end
  end

private

  # the base PATH environment variable to be used
  # @return [String] the resulting PATH
  def default_path
    "#{slug_vendor_base}/bin:/usr/local/bin:/usr/bin:/bin:bin"
  end

  # path to the vendored gems
  # @return [String] resulting path
  def language_pack_gems
    File.expand_path("../../../vendor/gems", __FILE__)
  end

  # the relative path to the bundler directory of gems
  # @return [String] resulting path
  def slug_vendor_base
    "vendor/bundle/ruby/1.9.1"
  end

  # sets up the environment variables for the build process
  def setup_language_pack_environment
    default_config_vars.each do |key, value|
      ENV[key] ||= value
    end
    ENV["GEM_HOME"] = slug_vendor_base
    ENV["PATH"] = default_config_vars["PATH"]
  end

  # list of default gems to vendor into the slug
  # @return [Array] resluting list of gems
  def gems
    [BUNDLER_GEM_PATH]
  end

  # installs vendored gems into the slug
  def install_language_pack_gems
    FileUtils.mkdir_p(slug_vendor_base)
    Dir.chdir(slug_vendor_base) do |dir|
      gems.each do |gem|
        run("curl #{VENDOR_URL}/#{gem}.tgz -s -o - | tar xzf -")
      end
      Dir["bin/*"].each {|path| run("chmod 755 #{path}") }
    end
  end

  # default set of binaries to install
  # @return [Array] resulting list
  def binaries
    []
  end

  # vendors binaries into the slug
  def install_binaries
    binaries.each {|binary| install_binary(binary) }
    Dir["bin/*"].each {|path| run("chmod +x #{path}") }
  end

  # vendors individual binary into the slug
  # @param [String] name of the binary package from S3.
  #   Example: https://s3.amazonaws.com/language-pack-ruby/node-0.4.7.tgz, where name is "node-0.4.7"
  def install_binary(name)
    bin_dir = "bin"
    FileUtils.mkdir_p bin_dir
    Dir.chdir(bin_dir) do |dir|
      run("curl #{VENDOR_URL}/#{name}.tgz -s -o - | tar xzf -")
    end
  end

  # removes a binary from the slug
  # @param [String] relative path of the binary on the slug
  def uninstall_binary(path)
    FileUtils.rm File.join('bin', File.basename(path)), :force => true
  end

  # install libyaml into the LP to be referenced for psych compilation
  # @param [String] tmpdir to store the libyaml files
  def install_libyaml(dir)
    FileUtils.mkdir_p dir
    Dir.chdir(dir) do |dir|
      run("curl #{VENDOR_URL}/#{LIBYAML_PATH}.tgz -s -o - | tar xzf -")
    end
  end

  # runs bundler to install the dependencies
  def build_bundler
    bundle_command = "bundle install --without development:test --path vendor/bundle"

    unless File.exist?("Gemfile.lock")
      error "Gemfile.lock is required. Please run \"bundle install\" locally\nand commit your Gemfile.lock."
    end

    if has_windows_gemfile_lock?
      File.unlink("Gemfile.lock")
    else
      # using --deployment is preferred if we can
      bundle_command += " --deployment"
      cache_load ".bundle"
    end

    cache_load "vendor/bundle"

    version = run("bundle version").strip
    topic("Installing dependencies using #{version}")

    Dir.mktmpdir("libyaml-") do |tmpdir|
      libyaml_dir = "#{tmpdir}/#{LIBYAML_PATH}"
      install_libyaml(libyaml_dir)

      # need to setup compile environment for the psych gem
      yaml_include   = File.expand_path("#{libyaml_dir}/include")
      yaml_lib       = File.expand_path("#{libyaml_dir}/lib")
      env_vars       = "env CPATH=#{yaml_include}:$CPATH CPPATH=#{yaml_include}:$CPPATH LIBRARY_PATH=#{yaml_lib}:$LIBRARY_PATH"
      puts "Running: #{bundle_command}"
      pipe("#{env_vars} #{bundle_command} --no-clean 2>&1")
    end

    if $?.success?
      puts "Cleaning up the bundler cache."
      run "bundle clean"
      cache_store ".bundle"
      cache_store "vendor/bundle"
    else
      error "Failed to install gems via Bundler."
    end
  end

  # writes ERB based database.yml for Rails. The database.yml uses the DATABASE_URL from the environment during runtime.
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

  # add bundler to the load path
  # NOTE: it sets a flag, so the path can only be loaded once
  def add_bundler_to_load_path
    return if @bundler_loadpath
    $: << File.expand_path(Dir["#{slug_vendor_base}/gems/bundler*/lib"].first)
    @Bundler_loadpath = true
  end

  # detects whether the Gemfile.lock contains the Windows platform
  # @return [Boolean] true if the Gemfile.lock was created on Windows
  def has_windows_gemfile_lock?
    add_bundler_to_load_path
    require "bundler"
    parser = Bundler::LockfileParser.new(File.read("Gemfile.lock"))
    parser.platforms.detect do |platform|
      /mingw|mswin/.match(platform.os) if platform.is_a?(Gem::Platform)
    end
  end

  # detects if a gem is in the bundle.
  # NOTE: it caches the output of `bundle show` on the first run, so this will break if `bundle show` changes between calls.
  # @param [String] name of the gem in question
  # @return [String, nil] if it finds the gem, it will return the line from bundle show or nil if nothing is found.
  def gem_is_bundled?(gem)
    @bundle_show ||= run("bundle show")
    @bundle_show.split("\n").detect { |line| line =~ / \* #{gem} / }
  end

  # detects if a rake task is defined in the app
  # @param [String] the task in question
  # @return [Boolean] true if the rake task is defined in the app
  def rake_task_defined?(task)
    run("env PATH=$PATH bundle exec rake #{task} --dry-run") && $?.success?
  end

  # executes the block without GIT_DIR environment variable removed since it can mess with the current working directory git thinks it's in
  # param [block] block to be executed in the GIT_DIR free context
  def allow_git(&blk)
    git_dir = ENV.delete("GIT_DIR") # can mess with bundler
    blk.call
    ENV["GIT_DIR"] = git_dir
  end
end
