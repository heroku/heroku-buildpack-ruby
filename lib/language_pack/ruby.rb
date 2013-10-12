require "tmpdir"
require "digest/md5"
require "rubygems"
require "language_pack"
require "language_pack/base"
require "language_pack/bundler_lockfile"

# base Ruby Language Pack. This is for any base ruby app.
class LanguagePack::Ruby < LanguagePack::Base
  include LanguagePack::BundlerLockfile
  extend LanguagePack::BundlerLockfile::ClassMethods

  NAME                 = "ruby"
  BUILDPACK_VERSION    = "v80"
  LIBYAML_VERSION      = "0.1.4"
  LIBYAML_PATH         = "libyaml-#{LIBYAML_VERSION}"
  BUNDLER_VERSION      = "1.3.2"
  BUNDLER_GEM_PATH     = "bundler-#{BUNDLER_VERSION}"
  NODE_VERSION         = "0.4.7"
  NODE_JS_BINARY_PATH  = "node-#{NODE_VERSION}"
  JVM_BASE_URL         = "http://heroku-jdk.s3.amazonaws.com"
  JVM_VERSION          = "openjdk7-latest"
  DEFAULT_RUBY_VERSION = "ruby-2.0.0"
  RBX_BASE_URL         = "http://binaries.rubini.us/heroku"

  # detects if this is a valid Ruby app
  # @return [Boolean] true if it's a Ruby app
  def self.use?
    instrument "ruby.use" do
      File.exist?("Gemfile")
    end
  end

  def self.gem_version(name)
    instrument "ruby.gem_version" do
      if gem = bundle.specs.detect {|g| g.name == name }
        gem.version
      end
    end
  end

  def initialize(build_path, cache_path=nil)
    super(build_path, cache_path)
    @fetchers[:jvm] = LanguagePack::Fetcher.new(JVM_BASE_URL)
    @fetchers[:rbx] = LanguagePack::Fetcher.new(RBX_BASE_URL)
  end

  def name
    "Ruby"
  end

  def default_addons
    instrument "ruby.default_addons" do
      add_dev_database_addon
    end
  end

  def default_config_vars
    instrument "ruby.default_config_vars" do
      vars = {
        "LANG"     => "en_US.UTF-8",
        "PATH"     => default_path,
        "GEM_PATH" => slug_vendor_base,
      }

      ruby_version_jruby? ? vars.merge({
        "JAVA_OPTS" => default_java_opts,
        "JRUBY_OPTS" => default_jruby_opts,
        "JAVA_TOOL_OPTIONS" => default_java_tool_options
      }) : vars
    end
  end

  def default_process_types
    instrument "ruby.default_process_types" do
      {
        "rake"    => "bundle exec rake",
        "console" => "bundle exec irb"
      }
    end
  end

  def compile
    instrument 'ruby.compile' do
      Dir.chdir(build_path)
      remove_vendor_bundle
      install_ruby
      install_jvm
      setup_language_pack_environment
      setup_profiled
      allow_git do
        install_language_pack_gems
        build_bundler
        create_database_yml
        install_binaries
        run_assets_precompile_rake_task
      end
      super
    end
  end

private

  # the base PATH environment variable to be used
  # @return [String] the resulting PATH
  def default_path
    "bin:#{bundler_binstubs_path}:/usr/local/bin:/usr/bin:/bin"
  end

  # the relative path to the bundler directory of gems
  # @return [String] resulting path
  def slug_vendor_base
    instrument 'ruby.slug_vendor_base' do
      if @slug_vendor_base
        @slug_vendor_base
      elsif @ruby_version == "ruby-1.8.7"
        @slug_vendor_base = "vendor/bundle/1.8"
      else
        @slug_vendor_base = run(%q(ruby -e "require 'rbconfig';puts \"vendor/bundle/#{RUBY_ENGINE}/#{RbConfig::CONFIG['ruby_version']}\"")).chomp
      end
    end
  end

  # the relative path to the vendored ruby directory
  # @return [String] resulting path
  def slug_vendor_ruby
    "vendor/#{ruby_version}"
  end

  # the relative path to the vendored jvm
  # @return [String] resulting path
  def slug_vendor_jvm
    "vendor/jvm"
  end

  # the absolute path of the build ruby to use during the buildpack
  # @return [String] resulting path
  def build_ruby_path
    "/tmp/#{ruby_version}"
  end

  # fetch the ruby version from bundler
  # @return [String, nil] returns the ruby version if detected or nil if none is detected
  def ruby_version
    instrument 'ruby.ruby_version' do
      return @ruby_version if @ruby_version_run

      @ruby_version_run     = true
      @ruby_version_set     = false

      old_system_path = "/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin"
      @ruby_version = run_stdout("env PATH=#{bundler_path}/bin:#{old_system_path} GEM_PATH=#{bundler_path} bundle platform --ruby").chomp

      if @ruby_version == "No ruby version specified"
        if new_app?
          @ruby_version = DEFAULT_RUBY_VERSION
        elsif !@metadata.exists?("buildpack_ruby_version")
          @ruby_version = "ruby-1.9.2"
        else
          @ruby_version = @metadata.read("buildpack_ruby_version").chomp
        end
      else
        @ruby_version     = @ruby_version.sub('(', '').sub(')', '').split.join('-')
        @ruby_version_set = true
      end
    end

    @ruby_version
  end

  # determine if we're using rbx
  # @return [Boolean] true if we are and false if we aren't
  def ruby_version_rbx?
    ruby_version ? ruby_version.match(/rbx-/) : false
  end

  # determine if we're using jruby
  # @return [Boolean] true if we are and false if we aren't
  def ruby_version_jruby?
    @ruby_version_jruby ||= ruby_version ? ruby_version.match(/jruby-/) : false
  end

  # default JAVA_OPTS
  # return [String] string of JAVA_OPTS
  def default_java_opts
    "-Xmx384m -Xss512k -XX:+UseCompressedOops -Dfile.encoding=UTF-8"
  end

  # default JRUBY_OPTS
  # return [String] string of JRUBY_OPTS
  def default_jruby_opts
    "-Xcompile.invokedynamic=false"
  end

  # default JAVA_TOOL_OPTIONS
  # return [String] string of JAVA_TOOL_OPTIONS
  def default_java_tool_options
    "-Djava.rmi.server.useCodebaseOnly=true"
  end

  # list the available valid ruby versions
  # @note the value is memoized
  # @return [Array] list of Strings of the ruby versions available
  def ruby_versions
    return @ruby_versions if @ruby_versions

    Dir.mktmpdir("ruby_versions-") do |tmpdir|
      Dir.chdir(tmpdir) do
        @fetchers[:buildpack].fetch("ruby_versions.yml")
        @ruby_versions = YAML::load_file("ruby_versions.yml")
      end
    end

    @ruby_versions
  end

  # sets up the environment variables for the build process
  def setup_language_pack_environment
    instrument 'ruby.setup_language_pack_environment' do
      setup_ruby_install_env

      config_vars = default_config_vars.each do |key, value|
        ENV[key] ||= value
      end
      ENV["GEM_HOME"] = slug_vendor_base
      ENV["GEM_PATH"] = slug_vendor_base
      ENV["PATH"]     = "#{ruby_install_binstub_path}:#{slug_vendor_base}/bin:#{config_vars["PATH"]}"
    end
  end

  # sets up the profile.d script for this buildpack
  def setup_profiled
    instrument 'setup_profiled' do
      set_env_override "GEM_PATH", "$HOME/#{slug_vendor_base}:$GEM_PATH"
      set_env_default  "LANG",     "en_US.UTF-8"
      set_env_override "PATH",     "$HOME/bin:$HOME/#{slug_vendor_base}/bin:$HOME/#{bundler_binstubs_path}:$PATH"

      if ruby_version_jruby?
        set_env_default "JAVA_OPTS", default_java_opts
        set_env_default "JRUBY_OPTS", default_jruby_opts
        set_env_default "JAVA_TOOL_OPTIONS", default_java_tool_options
      end
    end
  end

  # determines if a build ruby is required
  # @return [Boolean] true if a build ruby is required
  def build_ruby?
    @build_ruby ||= %w{ruby-1.8.7 ruby-1.9.2}.include?(ruby_version)
  end

  # install the vendored ruby
  # @return [Boolean] true if it installs the vendored ruby and false otherwise
  def install_ruby
    instrument 'ruby.install_ruby' do
      return false unless ruby_version

      invalid_ruby_version_message = <<ERROR
Invalid RUBY_VERSION specified: #{ruby_version}
Valid versions: #{ruby_versions.join(", ")}
ERROR

      if build_ruby?
        FileUtils.mkdir_p(build_ruby_path)
        Dir.chdir(build_ruby_path) do
          ruby_vm = "ruby"
          instrument "ruby.fetch_build_ruby" do
            @fetchers[:buildpack].fetch_untar("#{ruby_version.sub(ruby_vm, "#{ruby_vm}-build")}.tgz")
          end
        end
        error invalid_ruby_version_message unless $?.success?
      end

      FileUtils.mkdir_p(slug_vendor_ruby)
      Dir.chdir(slug_vendor_ruby) do
        instrument "ruby.fetch_ruby" do
          if ruby_version_rbx?
            file     = "#{ruby_version}.tar.bz2"
            sha_file = "#{file}.sha1"
            @fetchers[:rbx].fetch(file)
            @fetchers[:rbx].fetch(sha_file)

            expected_checksum = File.read(sha_file).chomp
            actual_checksum   = Digest::SHA1.file(file).hexdigest

            error <<-ERROR_MSG unless expected_checksum == actual_checksum
RBX Checksum for #{file} does not match.
Expected #{expected_checksum} but got #{actual_checksum}.
Please try pushing again in a few minutes.
ERROR_MSG

            run("tar jxf #{file}")
            FileUtils.mv(Dir.glob("app/#{slug_vendor_ruby}/*"), ".")
            FileUtils.rm_rf("app")
            FileUtils.rm(file)
            FileUtils.rm(sha_file)
          else
            @fetchers[:buildpack].fetch_untar("#{ruby_version}.tgz")
          end
        end
      end
      error invalid_ruby_version_message unless $?.success?

      app_bin_dir = "bin"
      FileUtils.mkdir_p app_bin_dir

      run("ln -s ruby #{slug_vendor_ruby}/bin/ruby.exe")

      Dir["#{slug_vendor_ruby}/bin/*"].each do |vendor_bin|
        run("ln -s ../#{vendor_bin} #{app_bin_dir}")
      end

      @metadata.write("buildpack_ruby_version", ruby_version)

      topic "Using Ruby version: #{ruby_version}"
      if !@ruby_version_set
        warn(<<WARNING)
You have not declared a Ruby version in your Gemfile.
To set your Ruby version add this line to your Gemfile:
#{ruby_version_to_gemfile}
# See https://devcenter.heroku.com/articles/ruby-versions for more information.
WARNING
      end
    end

    true
  end

  def ruby_version_to_gemfile
    parts = ruby_version.split('-')
    if parts.size > 2
      # not mri
      "ruby '#{parts[1]}', :engine => '#{parts[2]}', :engine_version => '#{parts.last}'"
    else
      "ruby '#{parts.last}'"
    end
  end

  def new_app?
    !File.exist?("vendor/heroku")
  end

  # vendors JVM into the slug for JRuby
  def install_jvm
    instrument 'ruby.install_jvm' do
      if ruby_version_jruby?
        topic "Installing JVM: #{JVM_VERSION}"

        FileUtils.mkdir_p(slug_vendor_jvm)
        Dir.chdir(slug_vendor_jvm) do
          @fetchers[:jvm].fetch_untar("#{JVM_VERSION}.tar.gz")
        end

        bin_dir = "bin"
        FileUtils.mkdir_p bin_dir
        Dir["#{slug_vendor_jvm}/bin/*"].each do |bin|
          run("ln -s ../#{bin} #{bin_dir}")
        end
      end
    end
  end

  # find the ruby install path for its binstubs during build
  # @return [String] resulting path or empty string if ruby is not vendored
  def ruby_install_binstub_path
    @ruby_install_binstub_path ||=
      if build_ruby?
        "#{build_ruby_path}/bin"
      elsif ruby_version
        "#{slug_vendor_ruby}/bin"
      else
        ""
      end
  end

  # setup the environment so we can use the vendored ruby
  def setup_ruby_install_env
    instrument 'ruby.setup_ruby_install_env' do
      ENV["PATH"] = "#{ruby_install_binstub_path}:#{ENV["PATH"]}"

      if ruby_version_jruby?
        ENV['JAVA_OPTS']  = default_java_opts
      end
    end
  end

  # list of default gems to vendor into the slug
  # @return [Array] resulting list of gems
  def gems
    [BUNDLER_GEM_PATH]
  end

  # installs vendored gems into the slug
  def install_language_pack_gems
    instrument 'ruby.install_language_pack_gems' do
      FileUtils.mkdir_p(slug_vendor_base)
      Dir.chdir(slug_vendor_base) do |dir|
        gems.each do |gem|
          @fetchers[:buildpack].fetch_untar("#{gem}.tgz")
        end
        Dir["bin/*"].each {|path| run("chmod 755 #{path}") }
      end
    end
  end

  # default set of binaries to install
  # @return [Array] resulting list
  def binaries
    add_node_js_binary
  end

  # vendors binaries into the slug
  def install_binaries
    instrument 'ruby.install_binaries' do
      binaries.each {|binary| install_binary(binary) }
      Dir["bin/*"].each {|path| run("chmod +x #{path}") }
    end
  end

  # vendors individual binary into the slug
  # @param [String] name of the binary package from S3.
  #   Example: https://s3.amazonaws.com/language-pack-ruby/node-0.4.7.tgz, where name is "node-0.4.7"
  def install_binary(name)
    bin_dir = "bin"
    FileUtils.mkdir_p bin_dir
    Dir.chdir(bin_dir) do |dir|
      @fetchers[:buildpack].fetch_untar("#{name}.tgz")
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
    instrument 'ruby.install_libyaml' do
      FileUtils.mkdir_p dir
      Dir.chdir(dir) do |dir|
        @fetchers[:buildpack].fetch_untar("#{LIBYAML_PATH}.tgz")
      end
    end
  end

  # remove `vendor/bundle` that comes from the git repo
  # in case there are native ext.
  # users should be using `bundle pack` instead.
  # https://github.com/heroku/heroku-buildpack-ruby/issues/21
  def remove_vendor_bundle
    if File.exists?("vendor/bundle")
      warn(<<WARNING)
Removing `vendor/bundle`.
Checking in `vendor/bundle` is not supported. Please remove this directory
and add it to your .gitignore. To vendor your gems with Bundler, use
`bundle pack` instead.
WARNING
      FileUtils.rm_rf("vendor/bundle")
    end
  end

  def bundler_binstubs_path
    "vendor/bundle/bin"
  end

  # runs bundler to install the dependencies
  def build_bundler
    instrument 'ruby.build_bundler' do
      log("bundle") do
        bundle_without = ENV["BUNDLE_WITHOUT"] || "development:test"
        bundle_bin     = "bundle"
        bundle_command = "#{bundle_bin} install --without #{bundle_without} --path vendor/bundle --binstubs #{bundler_binstubs_path}"

        unless File.exist?("Gemfile.lock")
          error "Gemfile.lock is required. Please run \"bundle install\" locally\nand commit your Gemfile.lock."
        end

        if has_windows_gemfile_lock?
          warn(<<WARNING)
Removing `Gemfile.lock` because it was generated on Windows.
Bundler will do a full resolve so native gems are handled properly.
This may result in unexpected gem versions being used in your app.
WARNING

          log("bundle", "has_windows_gemfile_lock")
          File.unlink("Gemfile.lock")
        else
          # using --deployment is preferred if we can
          bundle_command += " --deployment"
          cache.load ".bundle"
        end

        version = run_stdout("#{bundle_bin} version").strip
        topic("Installing dependencies using #{version}")

        load_bundler_cache

        bundler_output = ""
        Dir.mktmpdir("libyaml-") do |tmpdir|
          libyaml_dir = "#{tmpdir}/#{LIBYAML_PATH}"
          install_libyaml(libyaml_dir)

          # need to setup compile environment for the psych gem
          yaml_include   = File.expand_path("#{libyaml_dir}/include")
          yaml_lib       = File.expand_path("#{libyaml_dir}/lib")
          pwd            = run("pwd").chomp
          bundler_path   = "#{pwd}/#{slug_vendor_base}/gems/#{BUNDLER_GEM_PATH}/lib"
          # we need to set BUNDLE_CONFIG and BUNDLE_GEMFILE for
          # codon since it uses bundler.
          env_vars       = "env BUNDLE_GEMFILE=#{pwd}/Gemfile BUNDLE_CONFIG=#{pwd}/.bundle/config CPATH=#{yaml_include}:$CPATH CPPATH=#{yaml_include}:$CPPATH LIBRARY_PATH=#{yaml_lib}:$LIBRARY_PATH RUBYOPT=\"#{syck_hack}\" NOKOGIRI_USE_SYSTEM_LIBRARIES=true"
          env_vars      += " BUNDLER_LIB_PATH=#{bundler_path}" if ruby_version && ruby_version.match(/^ruby-1\.8\.7/)
          puts "Running: #{bundle_command}"
          instrument "ruby.bundle_install" do
            bundler_output << pipe("#{env_vars} #{bundle_command} --no-clean 2>&1")
          end
        end

        if $?.success?
          log "bundle", :status => "success"
          puts "Cleaning up the bundler cache."
          instrument "ruby.bundle_clean" do
            pipe "#{bundle_bin} clean 2> /dev/null"
          end
          cache.store ".bundle"
          cache.store "vendor/bundle"

          # Keep gem cache out of the slug
          FileUtils.rm_rf("#{slug_vendor_base}/cache")
        else
          log "bundle", :status => "failure"
          error_message = "Failed to install gems via Bundler."
          puts "Bundler Output: #{bundler_output}"
          if bundler_output.match(/Installing sqlite3 \([\w.]+\)( with native extensions)?\s+Gem::Installer::ExtensionBuildError: ERROR: Failed to build gem native extension./)
            error_message += <<ERROR


Detected sqlite3 gem which is not supported on Heroku.
https://devcenter.heroku.com/articles/sqlite3
ERROR
          end

          error error_message
        end
      end
    end
  end

  # RUBYOPT line that requires syck_hack file
  # @return [String] require string if needed or else an empty string
  def syck_hack
    instrument "ruby.syck_hack" do
      syck_hack_file = File.expand_path(File.join(File.dirname(__FILE__), "../../vendor/syck_hack"))
      ruby_version   = run_stdout('ruby -e "puts RUBY_VERSION"').chomp
      # < 1.9.3 includes syck, so we need to use the syck hack
      if Gem::Version.new(ruby_version) < Gem::Version.new("1.9.3")
        "-r#{syck_hack_file}"
      else
        ""
      end
    end
  end

  # writes ERB based database.yml for Rails. The database.yml uses the DATABASE_URL from the environment during runtime.
  def create_database_yml
    instrument 'ruby.create_database_yml' do
      log("create_database_yml") do
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

def attribute(name, value, force_string = false)
  if value
    value_string =
      if force_string
        '"' + value + '"'
      else
        value
      end
    "\#{name}: \#{value_string}"
  else
    ""
  end
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
  <%= attribute "password", password, true %>
  <%= attribute "host",     host %>
  <%= attribute "port",     port %>

<% params.each do |key, value| %>
  <%= key %>: <%= value.first %>
<% end %>
        DATABASE_YML
        end
      end
    end
  end

  # detects whether the Gemfile.lock contains the Windows platform
  # @return [Boolean] true if the Gemfile.lock was created on Windows
  def has_windows_gemfile_lock?
    bundle.platforms.detect do |platform|
      /mingw|mswin/.match(platform.os) if platform.is_a?(Gem::Platform)
    end
  end

  # detects if a gem is in the bundle.
  # @param [String] name of the gem in question
  # @return [String, nil] if it finds the gem, it will return the line from bundle show or nil if nothing is found.
  def gem_is_bundled?(gem)
    bundle.specs.map(&:name).include?(gem)
  end

  # detects if a rake task is defined in the app
  # @param [String] the task in question
  # @return [Boolean] true if the rake task is defined in the app
  def rake_task_defined?(task)
    instrument "ruby.rake_task_defined" do
      run("env PATH=$PATH bundle exec rake #{task} --dry-run") && $?.success?
    end
  end

  # executes the block with GIT_DIR environment variable removed since it can mess with the current working directory git thinks it's in
  # @param [block] block to be executed in the GIT_DIR free context
  def allow_git(&blk)
    git_dir = ENV.delete("GIT_DIR") # can mess with bundler
    blk.call
    ENV["GIT_DIR"] = git_dir
  end

  # decides if we need to enable the dev database addon
  # @return [Array] the database addon if the pg gem is detected or an empty Array if it isn't.
  def add_dev_database_addon
    gem_is_bundled?("pg") ? ['heroku-postgresql:dev'] : []
  end

  # decides if we need to install the node.js binary
  # @note execjs will blow up if no JS RUNTIME is detected and is loaded.
  # @return [Array] the node.js binary path if we need it or an empty Array
  def add_node_js_binary
    gem_is_bundled?('execjs') ? [NODE_JS_BINARY_PATH] : []
  end

  def run_assets_precompile_rake_task
    instrument 'ruby.run_assets_precompile_rake_task' do
      if rake_task_defined?("assets:precompile")
        require 'benchmark'

        topic "Running: rake assets:precompile"
        time = Benchmark.realtime { pipe("env PATH=$PATH:bin bundle exec rake assets:precompile 2>&1") }
        if $?.success?
          puts "Asset precompilation completed (#{"%.2f" % time}s)"
        end
      end
    end
  end

  def bundler_cache
    "vendor/bundle"
  end

  def load_bundler_cache
    instrument "ruby.load_bundler_cache" do
      cache.load "vendor"

      full_ruby_version       = run_stdout(%q(ruby -v)).chomp
      rubygems_version        = run_stdout(%q(gem -v)).chomp
      heroku_metadata         = "vendor/heroku"
      old_rubygems_version    = nil
      ruby_version_cache      = "ruby_version"
      buildpack_version_cache = "buildpack_version"
      bundler_version_cache   = "bundler_version"
      rubygems_version_cache  = "rubygems_version"

      old_rubygems_version = @metadata.read(ruby_version_cache).chomp if @metadata.exists?(ruby_version_cache)

      # fix bug from v37 deploy
      if File.exists?("vendor/ruby_version")
        puts "Broken cache detected. Purging build cache."
        cache.clear("vendor")
        FileUtils.rm_rf("vendor/ruby_version")
        purge_bundler_cache
        # fix bug introduced in v38
      elsif !@metadata.exists?(buildpack_version_cache) && @metadata.exists?(ruby_version_cache)
        puts "Broken cache detected. Purging build cache."
        purge_bundler_cache
      elsif cache.exists?(bundler_cache) && @metadata.exists?(ruby_version_cache) && full_ruby_version != @metadata.read(ruby_version_cache).chomp
        puts "Ruby version change detected. Clearing bundler cache."
        puts "Old: #{@metadata.read(ruby_version_cache).chomp}"
        puts "New: #{full_ruby_version}"
        purge_bundler_cache
      end

      # fix git gemspec bug from Bundler 1.3.0+ upgrade
      if File.exists?(bundler_cache) && !@metadata.exists?(bundler_version_cache) && !run("find vendor/bundle/*/*/bundler/gems/*/ -name *.gemspec").include?("No such file or directory")
        puts "Old bundler cache detected. Clearing bundler cache."
        purge_bundler_cache
      end

      # fix for https://github.com/heroku/heroku-buildpack-ruby/issues/86
      if (!@metadata.exists?(rubygems_version_cache) ||
          (old_rubygems_version == "2.0.0" && old_rubygems_version != rubygems_version)) &&
          @metadata.exists?(ruby_version_cache) && @metadata.read(ruby_version_cache).chomp.include?("ruby 2.0.0p0")
        puts "Updating to rubygems #{rubygems_version}. Clearing bundler cache."
        purge_bundler_cache
      end

      # fix for https://github.com/sparklemotion/nokogiri/issues/923
      if @metadata.exists?(buildpack_version_cache) && @metadata.read(buildpack_version_cache).sub('v', '').to_i <= 76
        puts "Fixing nokogiri install. Clearing bundler cache."
        puts "See https://github.com/sparklemotion/nokogiri/issues/923."
        purge_bundler_cache
      end

      FileUtils.mkdir_p(heroku_metadata)
      @metadata.write(ruby_version_cache, full_ruby_version, false)
      @metadata.write(buildpack_version_cache, BUILDPACK_VERSION, false)
      @metadata.write(bundler_version_cache, BUNDLER_VERSION, false)
      @metadata.write(rubygems_version_cache, rubygems_version, false)
      @metadata.save
    end
  end

  def purge_bundler_cache
    instrument "ruby.purge_bundler_cache" do
      FileUtils.rm_rf(bundler_cache)
      cache.clear bundler_cache
      # need to reinstall language pack gems
      install_language_pack_gems
    end
  end
end
