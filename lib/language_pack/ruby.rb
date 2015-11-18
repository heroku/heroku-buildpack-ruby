require "tmpdir"
require "digest/md5"
require "benchmark"
require "rubygems"
require "language_pack"
require "language_pack/base"
require "language_pack/ruby_version"
require "language_pack/helpers/node_installer"
require "language_pack/helpers/jvm_installer"
require "language_pack/version"

# base Ruby Language Pack. This is for any base ruby app.
class LanguagePack::Ruby < LanguagePack::Base
  NAME                 = "ruby"
  LIBYAML_VERSION      = "0.1.6"
  LIBYAML_PATH         = "libyaml-#{LIBYAML_VERSION}"
  BUNDLER_VERSION      = "1.9.7"
  BUNDLER_GEM_PATH     = "bundler-#{BUNDLER_VERSION}"
  DEFAULT_RUBY_VERSION = "ruby-2.0.0"
  RBX_BASE_URL         = "http://binaries.rubini.us/heroku"
  NODE_BP_PATH         = "vendor/node/bin"

  # detects if this is a valid Ruby app
  # @return [Boolean] true if it's a Ruby app
  def self.use?
    instrument "ruby.use" do
      File.exist?("Gemfile")
    end
  end

  def self.bundler
    @@bundler ||= LanguagePack::Helpers::BundlerWrapper.new.install
  end

  def bundler
    self.class.bundler
  end

  def initialize(build_path, cache_path=nil)
    super(build_path, cache_path)
    @fetchers[:mri]    = LanguagePack::Fetcher.new(VENDOR_URL, @stack)
    @fetchers[:rbx]    = LanguagePack::Fetcher.new(RBX_BASE_URL, @stack)
    @node_installer    = LanguagePack::NodeInstaller.new(@stack)
    @jvm_installer     = LanguagePack::JvmInstaller.new(slug_vendor_jvm, @stack)
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
        "LANG" => env("LANG") || "en_US.UTF-8"
      }

      ruby_version.jruby? ? vars.merge({
        "JAVA_OPTS" => default_java_opts,
        "JRUBY_OPTS" => default_jruby_opts
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

  def best_practice_warnings
    if bundler.has_gem?("asset_sync")
      warn(<<-WARNING)
You are using the `asset_sync` gem.
See https://devcenter.heroku.com/articles/please-do-not-use-asset-sync for more information.
WARNING
    end
  end

  def compile
    instrument 'ruby.compile' do
      # check for new app at the beginning of the compile
      new_app?
      Dir.chdir(build_path)
      remove_vendor_bundle
      install_ruby
      install_jvm
      setup_language_pack_environment
      setup_export
      setup_profiled
      allow_git do
        install_bundler_in_app
        build_bundler
        post_bundler
        create_database_yml
        install_binaries
        run_assets_precompile_rake_task
      end
      best_practice_warnings
      super
    end
  end

private

  # the base PATH environment variable to be used
  # @return [String] the resulting PATH
  def default_path
    # need to remove bin/ folder since it links
    # to the wrong --prefix ruby binstubs
    # breaking require. This only applies to Ruby 1.9.2 and 1.8.7.
    safe_binstubs = binstubs_relative_paths - ["bin"]
    paths         = [
      ENV["PATH"],
      "bin",
      system_paths,
    ]
    paths.unshift("#{slug_vendor_jvm}/bin") if ruby_version.jruby?
    paths.unshift(safe_binstubs)

    paths.join(":")
  end

  def binstubs_relative_paths
    [
      "bin",
      bundler_binstubs_path,
      "#{slug_vendor_base}/bin"
    ]
  end

  def system_paths
    "/usr/local/bin:/usr/bin:/bin"
  end

  # the relative path to the bundler directory of gems
  # @return [String] resulting path
  def slug_vendor_base
    instrument 'ruby.slug_vendor_base' do
      if @slug_vendor_base
        @slug_vendor_base
      elsif ruby_version.ruby_version == "1.8.7"
        @slug_vendor_base = "vendor/bundle/1.8"
      else
        @slug_vendor_base = run_no_pipe(%q(ruby -e "require 'rbconfig';puts \"vendor/bundle/#{RUBY_ENGINE}/#{RbConfig::CONFIG['ruby_version']}\"")).chomp
        error "Problem detecting bundler vendor directory: #{@slug_vendor_base}" unless $?.success?
        @slug_vendor_base
      end
    end
  end

  # the relative path to the vendored ruby directory
  # @return [String] resulting path
  def slug_vendor_ruby
    "vendor/#{ruby_version.version_without_patchlevel}"
  end

  # the relative path to the vendored jvm
  # @return [String] resulting path
  def slug_vendor_jvm
    "vendor/jvm"
  end

  # the absolute path of the build ruby to use during the buildpack
  # @return [String] resulting path
  def build_ruby_path
    "/tmp/#{ruby_version.version_without_patchlevel}"
  end

  # fetch the ruby version from bundler
  # @return [String, nil] returns the ruby version if detected or nil if none is detected
  def ruby_version
    instrument 'ruby.ruby_version' do
      return @ruby_version if @ruby_version
      new_app           = !File.exist?("vendor/heroku")
      last_version_file = "buildpack_ruby_version"
      last_version      = nil
      last_version      = @metadata.read(last_version_file).chomp if @metadata.exists?(last_version_file)

      @ruby_version = LanguagePack::RubyVersion.new(bundler.ruby_version,
        is_new:       new_app,
        last_version: last_version)
      return @ruby_version
    end
  end

  # default JAVA_OPTS
  # return [String] string of JAVA_OPTS
  def default_java_opts
    "-Xss512k -XX:+UseCompressedOops -Dfile.encoding=UTF-8"
  end

  def set_jvm_max_heap
    <<-EOF
case $(ulimit -u) in
256)   # 1X Dyno
  JVM_MAX_HEAP=384
  ;;
512)   # 2X Dyno
  JVM_MAX_HEAP=768
  ;;
16384) # IX Dyno
  JVM_MAX_HEAP=2048
  ;;
32768) # PX Dyno
  JVM_MAX_HEAP=5120
  ;;
esac
EOF
  end

  def set_java_mem
    <<-EOF
if ! [[ "${JAVA_OPTS}" == *-Xmx* ]]; then
  export JAVA_MEM=${JAVA_MEM:--Xmx${JVM_MAX_HEAP:-384}m}
fi
EOF
  end

  def set_default_web_concurrency
    <<-EOF
case $(ulimit -u) in
256)
  export HEROKU_RAM_LIMIT_MB=${HEROKU_RAM_LIMIT_MB:-512}
  export WEB_CONCURRENCY=${WEB_CONCURRENCY:-2}
  ;;
512)
  export HEROKU_RAM_LIMIT_MB=${HEROKU_RAM_LIMIT_MB:-1024}
  export WEB_CONCURRENCY=${WEB_CONCURRENCY:-4}
  ;;
32768)
  export HEROKU_RAM_LIMIT_MB=${HEROKU_RAM_LIMIT_MB:-6144}
  export WEB_CONCURRENCY=${WEB_CONCURRENCY:-16}
  ;;
*)
  ;;
esac
EOF
  end

  # default JRUBY_OPTS
  # return [String] string of JRUBY_OPTS
  def default_jruby_opts
    "-Xcompile.invokedynamic=false"
  end

  # default Java Xmx
  # return [String] string of Java Xmx
  def default_java_mem
    "-Xmx${JVM_MAX_HEAP:-384}m"
  end

  # sets up the environment variables for the build process
  def setup_language_pack_environment
    instrument 'ruby.setup_language_pack_environment' do
      if ruby_version.jruby?
        ENV["PATH"] += ":bin"
        ENV["JAVA_MEM"] = run(<<-SHELL).chomp
#{set_jvm_max_heap}
echo #{default_java_mem}
SHELL
        ENV["JRUBY_OPTS"] = env('JRUBY_BUILD_OPTS') || env('JRUBY_OPTS')
      end
      setup_ruby_install_env
      ENV["PATH"] += ":#{node_preinstall_bin_path}" if node_js_installed?

      # TODO when buildpack-env-args rolls out, we can get rid of
      # ||= and the manual setting below
      config_vars = default_config_vars.each do |key, value|
        ENV[key] ||= value
      end

      ENV["GEM_PATH"] = slug_vendor_base
      ENV["GEM_HOME"] = slug_vendor_base
      ENV["PATH"]     = default_path
    end
  end

  # Sets up the environment variables for subsequent processes run by
  # muiltibuildpack. We can't use profile.d because $HOME isn't set up
  def setup_export
    instrument 'ruby.setup_export' do
      paths = ENV["PATH"].split(":")
      set_export_override "GEM_PATH", "#{build_path}/#{slug_vendor_base}:$GEM_PATH"
      set_export_default  "LANG",     "en_US.UTF-8"
      set_export_override "PATH",     paths.map { |path| /^\/.*/ !~ path ? "#{build_path}/#{path}" : path }.join(":")

      if ruby_version.jruby?
        add_to_export set_jvm_max_heap
        add_to_export set_java_mem
        set_export_default "JAVA_OPTS",  default_java_opts
        set_export_default "JRUBY_OPTS", default_jruby_opts
      end
    end
  end

  # sets up the profile.d script for this buildpack
  def setup_profiled
    instrument 'setup_profiled' do
      set_env_default  "LANG",     "en_US.UTF-8"
      set_env_override "GEM_PATH", "$HOME/#{slug_vendor_base}:$GEM_PATH"
      set_env_override "PATH",     binstubs_relative_paths.map {|path| "$HOME/#{path}" }.join(":") + ":$PATH"

      add_to_profiled set_default_web_concurrency if env("SENSIBLE_DEFAULTS")

      if ruby_version.jruby?
        add_to_profiled set_jvm_max_heap
        add_to_profiled set_java_mem
        set_env_default "JAVA_OPTS", default_java_opts
        set_env_default "JRUBY_OPTS", default_jruby_opts
      end
    end
  end

  # install the vendored ruby
  # @return [Boolean] true if it installs the vendored ruby and false otherwise
  def install_ruby
    instrument 'ruby.install_ruby' do
      return false unless ruby_version

      if ruby_version.build?
        FileUtils.mkdir_p(build_ruby_path)
        Dir.chdir(build_ruby_path) do
          ruby_vm = "ruby"
          instrument "ruby.fetch_build_ruby" do
            @fetchers[:mri].fetch_untar("#{ruby_version.version.sub(ruby_vm, "#{ruby_vm}-build")}.tgz")
          end
        end
      end

      FileUtils.mkdir_p(slug_vendor_ruby)
      Dir.chdir(slug_vendor_ruby) do
        instrument "ruby.fetch_ruby" do
          if ruby_version.rbx?
            file     = "#{ruby_version.version}.tar.bz2"
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
            @fetchers[:mri].fetch_untar("#{ruby_version.version}.tgz")
          end
        end
      end

      app_bin_dir = "bin"
      FileUtils.mkdir_p app_bin_dir

      run("ln -s ruby #{slug_vendor_ruby}/bin/ruby.exe")

      Dir["#{slug_vendor_ruby}/bin/*"].each do |vendor_bin|
        run("ln -s ../#{vendor_bin} #{app_bin_dir}")
      end

      @metadata.write("buildpack_ruby_version", ruby_version.version)

      topic "Using Ruby version: #{ruby_version.version}"
      if !ruby_version.set
        warn(<<-WARNING)
You have not declared a Ruby version in your Gemfile.
To set your Ruby version add this line to your Gemfile:
#{ruby_version.to_gemfile}
# See https://devcenter.heroku.com/articles/ruby-versions for more information.
WARNING
      end
    end

    true
  rescue LanguagePack::Fetcher::FetchError => error
    if ruby_version.jruby?
      message = <<ERROR
An error occurred while installing Ruby #{ruby_version.version}
For supported Ruby versions see https://devcenter.heroku.com/articles/ruby-support#supported-runtimes
Note: Only JRuby 1.7.13 and newer are supported on Cedar-14
#{error.message}
ERROR
    else
      message = <<ERROR
An error occurred while installing Ruby #{ruby_version.version}
For supported Ruby versions see https://devcenter.heroku.com/articles/ruby-support#supported-runtimes
Note: Only the most recent version of Ruby 2.1 is supported on Cedar-14
#{error.message}
ERROR
    end
    error message
  end

  def new_app?
    @new_app ||= !File.exist?("vendor/heroku")
  end

  # vendors JVM into the slug for JRuby
  def install_jvm(forced = false)
    instrument 'ruby.install_jvm' do
      if ruby_version.jruby? || forced
        @jvm_installer.install(ruby_version.engine_version, forced)
      end
    end
  end

  # find the ruby install path for its binstubs during build
  # @return [String] resulting path or empty string if ruby is not vendored
  def ruby_install_binstub_path
    @ruby_install_binstub_path ||=
      if ruby_version.build?
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

      if ruby_version.jruby?
        ENV['JAVA_OPTS']  = default_java_opts
      end
    end
  end

  # installs vendored gems into the slug
  def install_bundler_in_app
    instrument 'ruby.install_language_pack_gems' do
      FileUtils.mkdir_p(slug_vendor_base)
      Dir.chdir(slug_vendor_base) do |dir|
        `cp -R #{bundler.bundler_path}/. .`
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
      if name.match(/^node\-/)
        @node_installer.install
      else
        @fetchers[:buildpack].fetch_untar("#{name}.tgz")
      end
    end
  end

  # removes a binary from the slug
  # @param [String] relative path of the binary on the slug
  def uninstall_binary(path)
    FileUtils.rm File.join('bin', File.basename(path)), :force => true
  end

  def load_default_cache?
    new_app? && ruby_version.default?
  end

  # loads a default bundler cache for new apps to speed up initial bundle installs
  def load_default_cache
    instrument "ruby.load_default_cache" do
      if false # load_default_cache?
        puts "New app detected loading default bundler cache"
        patchlevel = run("ruby -e 'puts RUBY_PATCHLEVEL'").chomp
        cache_name  = "#{DEFAULT_RUBY_VERSION}-p#{patchlevel}-default-cache"
        @fetchers[:buildpack].fetch_untar("#{cache_name}.tgz")
      end
    end
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
      warn(<<-WARNING)
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
        bundle_without = env("BUNDLE_WITHOUT") || "development:test"
        bundle_bin     = "bundle"
        bundle_command = "#{bundle_bin} install --without #{bundle_without} --path vendor/bundle --binstubs #{bundler_binstubs_path}"
        bundle_command << " -j4"

        if bundler.windows_gemfile_lock?
          warn(<<-WARNING, inline: true)
Removing `Gemfile.lock` because it was generated on Windows.
Bundler will do a full resolve so native gems are handled properly.
This may result in unexpected gem versions being used in your app.
In rare occasions Bundler may not be able to resolve your dependencies at all.
https://devcenter.heroku.com/articles/bundler-windows-gemfile
WARNING

          log("bundle", "has_windows_gemfile_lock")
          File.unlink("Gemfile.lock")
        else
          # using --deployment is preferred if we can
          bundle_command += " --deployment"
          cache.load ".bundle"
        end

        topic("Installing dependencies using bundler #{bundler.version}")
        load_bundler_cache

        bundler_output = ""
        bundle_time    = nil
        Dir.mktmpdir("libyaml-") do |tmpdir|
          libyaml_dir = "#{tmpdir}/#{LIBYAML_PATH}"
          install_libyaml(libyaml_dir)

          # need to setup compile environment for the psych gem
          yaml_include   = File.expand_path("#{libyaml_dir}/include").shellescape
          yaml_lib       = File.expand_path("#{libyaml_dir}/lib").shellescape
          pwd            = Dir.pwd
          bundler_path   = "#{pwd}/#{slug_vendor_base}/gems/#{BUNDLER_GEM_PATH}/lib"
          # we need to set BUNDLE_CONFIG and BUNDLE_GEMFILE for
          # codon since it uses bundler.
          env_vars       = {
            "BUNDLE_GEMFILE"                => "#{pwd}/Gemfile",
            "BUNDLE_CONFIG"                 => "#{pwd}/.bundle/config",
            "CPATH"                         => noshellescape("#{yaml_include}:$CPATH"),
            "CPPATH"                        => noshellescape("#{yaml_include}:$CPPATH"),
            "LIBRARY_PATH"                  => noshellescape("#{yaml_lib}:$LIBRARY_PATH"),
            "RUBYOPT"                       => syck_hack,
            "NOKOGIRI_USE_SYSTEM_LIBRARIES" => "true"
          }
          env_vars["BUNDLER_LIB_PATH"] = "#{bundler_path}" if ruby_version.ruby_version == "1.8.7"
          puts "Running: #{bundle_command}"
          instrument "ruby.bundle_install" do
            bundle_time = Benchmark.realtime do
              bundler_output << pipe("#{bundle_command} --no-clean", out: "2>&1", env: env_vars, user_env: true)
            end
          end
        end

        if $?.success?
          puts "Bundle completed (#{"%.2f" % bundle_time}s)"
          log "bundle", :status => "success"
          puts "Cleaning up the bundler cache."
          instrument "ruby.bundle_clean" do
            # Only show bundle clean output when not using default cache
            if load_default_cache?
              run("#{bundle_bin} clean > /dev/null", user_env: true)
            else
              pipe("#{bundle_bin} clean", out: "2> /dev/null", user_env: true)
            end
          end
          @bundler_cache.store

          # Keep gem cache out of the slug
          FileUtils.rm_rf("#{slug_vendor_base}/cache")
        else
          log "bundle", :status => "failure"
          error_message = "Failed to install gems via Bundler."
          puts "Bundler Output: #{bundler_output}"
          if bundler_output.match(/An error occurred while installing sqlite3/)
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

  def post_bundler
    instrument "ruby.post_bundler" do
      Dir[File.join(slug_vendor_base, "**", ".git")].each do |dir|
        FileUtils.rm_rf(dir)
      end
      bundler.clean
    end
  end

  # RUBYOPT line that requires syck_hack file
  # @return [String] require string if needed or else an empty string
  def syck_hack
    instrument "ruby.syck_hack" do
      syck_hack_file = File.expand_path(File.join(File.dirname(__FILE__), "../../vendor/syck_hack"))
      rv             = run_stdout('ruby -e "puts RUBY_VERSION"').chomp
      # < 1.9.3 includes syck, so we need to use the syck hack
      if Gem::Version.new(rv) < Gem::Version.new("1.9.3")
        "-r#{syck_hack_file}"
      else
        ""
      end
    end
  end

  # writes ERB based database.yml for Rails. The database.yml uses the DATABASE_URL from the environment during runtime.
  def create_database_yml
    instrument 'ruby.create_database_yml' do
      return false unless File.directory?("config")
      return false if  bundler.has_gem?('activerecord') && bundler.gem_version('activerecord') >= Gem::Version.new('4.1.0.beta1')

      log("create_database_yml") do
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

  def rake
    @rake ||= begin
      LanguagePack::Helpers::RakeRunner.new(
                bundler.has_gem?("rake") || ruby_version.rake_is_vendored?
              ).load_rake_tasks!(env: rake_env)
    end
  end

  def rake_env
    if database_url
      { "DATABASE_URL" => database_url }
    else
      {}
    end.merge(user_env_hash)
  end

  def database_url
    env("DATABASE_URL") if env("DATABASE_URL")
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
    bundler.has_gem?("pg") ? ['heroku-postgresql:hobby-dev'] : []
  end

  # decides if we need to install the node.js binary
  # @note execjs will blow up if no JS RUNTIME is detected and is loaded.
  # @return [Array] the node.js binary path if we need it or an empty Array
  def add_node_js_binary
    bundler.has_gem?('execjs') && node_not_preinstalled? ? [@node_installer.binary_path] : []
  end

  # checks if node.js is installed via the official heroku-buildpack-nodejs using multibuildpack
  # @return String if it's detected and false if it isn't
  def node_preinstall_bin_path
    return @node_preinstall_bin_path if defined?(@node_preinstall_bin_path)

    legacy_path = "#{Dir.pwd}/#{NODE_BP_PATH}"
    path        = run("which node")
    if path && $?.success?
      @node_preinstall_bin_path = path
    elsif run("#{legacy_path}/node -v") && $?.success?
      @node_preinstall_bin_path = legacy_path
    else
      @node_preinstall_bin_path = false
    end
  end
  alias :node_js_installed? :node_preinstall_bin_path

  def node_not_preinstalled?
    !node_js_installed?
  end

  def run_assets_precompile_rake_task
    instrument 'ruby.run_assets_precompile_rake_task' do

      precompile = rake.task("assets:precompile")
      return true unless precompile.is_defined?

      topic "Precompiling assets"
      precompile.invoke(env: rake_env)
      if precompile.success?
        puts "Asset precompilation completed (#{"%.2f" % precompile.time}s)"
      else
        precompile_fail(precompile.output)
      end
    end
  end

  def precompile_fail(output)
    log "assets_precompile", :status => "failure"
    msg = "Precompiling assets failed.\n"
    if output.match(/(127\.0\.0\.1)|(org\.postgresql\.util)/)
      msg << "Attempted to access a nonexistent database:\n"
      msg << "https://devcenter.heroku.com/articles/pre-provision-database\n"
    end
    error msg
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
      stack_cache             = "stack"

      old_rubygems_version = @metadata.read(ruby_version_cache).chomp if @metadata.exists?(ruby_version_cache)
      old_stack = @metadata.read(stack_cache).chomp if @metadata.exists?(stack_cache)
      old_stack ||= DEFAULT_LEGACY_STACK

      stack_change  = old_stack != @stack
      convert_stack = @bundler_cache.old?
      @bundler_cache.convert_stack(stack_change) if convert_stack
      if !new_app? && stack_change
        puts "Purging Cache. Changing stack from #{old_stack} to #{@stack}"
        purge_bundler_cache(old_stack)
      elsif !new_app? && !convert_stack
        @bundler_cache.load
      end

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
      elsif (@bundler_cache.exists? || @bundler_cache.old?) && @metadata.exists?(ruby_version_cache) && full_ruby_version != @metadata.read(ruby_version_cache).chomp
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
      if @metadata.exists?(buildpack_version_cache) && (bv = @metadata.read(buildpack_version_cache).sub('v', '').to_i) && bv != 0 && bv <= 76
        puts "Fixing nokogiri install. Clearing bundler cache."
        puts "See https://github.com/sparklemotion/nokogiri/issues/923."
        purge_bundler_cache
      end

      # recompile nokogiri to use new libyaml
      if @metadata.exists?(buildpack_version_cache) && (bv = @metadata.read(buildpack_version_cache).sub('v', '').to_i) && bv != 0 && bv <= 99 && bundler.has_gem?("psych")
        puts "Need to recompile psych for CVE-2013-6393. Clearing bundler cache."
        puts "See http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=737076."
        purge_bundler_cache
      end

      FileUtils.mkdir_p(heroku_metadata)
      @metadata.write(ruby_version_cache, full_ruby_version, false)
      @metadata.write(buildpack_version_cache, BUILDPACK_VERSION, false)
      @metadata.write(bundler_version_cache, BUNDLER_VERSION, false)
      @metadata.write(rubygems_version_cache, rubygems_version, false)
      @metadata.write(stack_cache, @stack, false)
      @metadata.save
    end
  end

  def purge_bundler_cache(stack = nil)
    instrument "ruby.purge_bundler_cache" do
      @bundler_cache.clear(stack)
      # need to reinstall language pack gems
      install_bundler_in_app
    end
  end
end
