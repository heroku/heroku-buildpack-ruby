require "tmpdir"
require "digest/md5"
require "benchmark"
require "rubygems"
require "language_pack"
require "language_pack/base"
require "language_pack/ruby_version"
require "language_pack/helpers/nodebin"
require "language_pack/helpers/node_installer"
require "language_pack/helpers/yarn_installer"
require "language_pack/helpers/binstub_check"
require "language_pack/version"

# base Ruby Language Pack. This is for any base ruby app.
class LanguagePack::Ruby < LanguagePack::Base
  NAME                 = "ruby"
  NODE_BP_PATH         = "vendor/node/bin"

  # detects if this is a valid Ruby app
  # @return [Boolean] true if it's a Ruby app
  def self.use?(bundler: nil)
    File.exist?("Gemfile")
  end

  def initialize(...)
    super(...)
    @node_installer = LanguagePack::Helpers::NodeInstaller.new(arch: @arch)
    @yarn_installer = LanguagePack::Helpers::YarnInstaller.new
  end

  def name
    "Ruby"
  end

  def default_addons
    add_dev_database_addon
  end

  # Environment variable defaults that are passed to ENV, `export` (for future buildpacks), and `.profile.d` (for launch/runtime)
  #
  # All values returned must be sourced from Heroku. User provided config vars
  # are handled in the interfaces that consume this method's result.
  #
  # @param environment_name [String] the environment name to use for RACK_ENV/RAILS_ENV
  # @return [Hash] the ENV var like result
  def self.default_config_vars(metadata:, ruby_version:, bundler:, environment_name:)
    @app_secret ||= begin
      if metadata.exists?("secret_key_base")
        metadata.read("secret_key_base").strip
      else
        SecureRandom.hex(64).tap {|secret| metadata.write("secret_key_base", secret) }
      end
    end

    LanguagePack::Helpers::DefaultEnvVars.call(
      is_jruby: ruby_version.jruby?,
      rack_version: bundler.gem_version("rack"),
      rails_version: bundler.gem_version("railties"),
      secret_key_base: @app_secret,
      environment_name: environment_name
    )
  end

  def default_process_types
    {
      "rake"    => "bundle exec rake",
      "console" => "bundle exec irb"
    }
  end

  def best_practice_warnings
    if bundler.has_gem?("asset_sync")
      warn(<<~WARNING)
        You are using the `asset_sync` gem.
        This is not recommended.
        See https://devcenter.heroku.com/articles/please-do-not-use-asset-sync for more information.
      WARNING
    end
  end

  def compile
    @outdated_version_check = LanguagePack::Helpers::OutdatedRubyVersion.new(
      current_ruby_version: ruby_version,
      fetcher: LanguagePack::Installers::HerokuRubyInstaller.fetcher(multi_arch_stacks: MULTI_ARCH_STACKS, stack: stack, arch: @arch),
    ).call

    @warn_io.warnings.each { |warning| self.warnings << warning }

    post_bundler(ruby_version: @ruby_version, app_path: app_path)
    create_database_yml
    install_binaries
    run_assets_precompile_rake_task
    @report.capture(
      "gem.railties_version" => bundler.gem_version('railties'),
      "gem.rack_version" => bundler.gem_version('rack')
    )
    if (puma_version = bundler.gem_version("puma"))
      @report.capture(
        "gem.puma_version" => puma_version
      )

      puma_warn_error = LanguagePack::Helpers::PumaWarnError.new(
        puma_version: puma_version,
        env: user_env_hash
      )

      error(puma_warn_error.error) if puma_warn_error.error
      puma_warn_error.warnings.each do |warning|
        warn(warning)
      end
    end
    config_detect
    best_practice_warnings
    warn_outdated_ruby
    default_config_vars = self.class.default_config_vars(metadata: @metadata, ruby_version: @ruby_version, bundler: bundler, environment_name: environment_name)
    setup_profiled(ruby_layer_path: "$HOME", gem_layer_path: "$HOME", ruby_version: @ruby_version, default_config_vars: default_config_vars) # $HOME is set to /app at run time
    setup_export(app_path: app_path, ruby_version: @ruby_version, default_config_vars: default_config_vars)
    cleanup
    super
  rescue => e
    warn_outdated_ruby
    raise e
  end

  def cleanup
  end

  def config_detect
  end

  # Runs `bundle list` and optionally streams the result to the user
  #
  # Streaming helps with build log visibility i.e. "what version of X" am I using at a glance.
  #
  # Checks if the information from `bundle list` matches information collected from bundler internals
  # if not, emits the difference. The goal is to eventually replace requiring bundler internals with
  # information retrieved from `bundle list`.
  def self.bundle_list(stream_to_user: , io:, report: HerokuBuildReport::GLOBAL)
    LanguagePack::Helpers::BundleList::HumanCommand.new(
      io: io,
      stream_to_user: stream_to_user
    ).call
  end

private

  # A bad shebang line looks like this:
  #
  # ```
  # #!/usr/bin/env ruby2.5
  # ```
  #
  # Since `ruby2.5` is not a valid binary name
  #
  def self.warn_bad_binstubs(app_path: , warn_object: )
    check = LanguagePack::Helpers::BinstubCheck.new(
      warn_object: warn_object,
      app_root_dir: app_path,
    )
    check.call
  end

  def default_malloc_arena_max?
    return true if @metadata.exists?("default_malloc_arena_max")
    return @metadata.write("default_malloc_arena_max", "true") if new_app?

    return false
  end

  def self.warn_bundler_upgrade(metadata: , bundler_version: )
    old_bundler_version  = metadata.read("bundler_version").strip if metadata.exists?("bundler_version")

    if old_bundler_version && old_bundler_version != bundler_version
      warn(<<~WARNING, inline: true)
        Your app was upgraded to bundler #{ bundler_version }.
        Previously you had a successful deploy with bundler #{ old_bundler_version }.

        If you see problems related to the bundler version please refer to:
        https://devcenter.heroku.com/articles/bundler-version#known-upgrade-issues

      WARNING
    end
  end

  def self.install_ruby_path(app_path: , ruby_version: )
    app_path.join("vendor").join(ruby_version.version_for_download)
  end

  # fetch the ruby version from bundler
  # @return [String, nil] returns the ruby version if detected or nil if none is detected
  def ruby_version
    @ruby_version or raise "Internal error: @ruby_version is not set. Call `get_ruby_version` and set @ruby_version"
  end

  def self.get_ruby_version(metadata: , gemfile_lock: , report: HerokuBuildReport::GLOBAL)
    lockfile_ruby_version = LanguagePack::RubyVersion.from_gemfile_lock(
      ruby: gemfile_lock.ruby,
      last_version: metadata.try_read("buildpack_ruby_version")
    )
    report.capture(
      "gemfile_lock.ruby_version.version" => lockfile_ruby_version.ruby_version,
      "gemfile_lock.ruby_version.engine" => lockfile_ruby_version.engine,
      "gemfile_lock.ruby_version.engine.version" => lockfile_ruby_version.engine_version,
      "gemfile_lock.ruby_version.major" => lockfile_ruby_version.major,
      "gemfile_lock.ruby_version.minor" => lockfile_ruby_version.minor,
      "gemfile_lock.ruby_version.patch" => lockfile_ruby_version.patch,
      "gemfile_lock.ruby_version.default" => lockfile_ruby_version.default?,
    )

    lockfile_ruby_version
  end

  def set_default_web_concurrency
    warn(<<~WARNING)
      Your application is using an undocumented feature SENSIBLE_DEFAULTS

      This feature is not supported and may be removed at any time. Please remove the SENSIBLE_DEFAULTS environment variable from your app.

      $ heroku config:unset SENSIBLE_DEFAULTS

      To configure your application's web concurrency, use the WEB_CONCURRENCY environment variable following this documentation:

      - https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#recommended-default-puma-process-and-thread-configuration
      - https://devcenter.heroku.com/articles/h12-request-timeout-in-ruby-mri#puma-pool-usage
      - https://help.heroku.com/88G3XLA6/what-is-an-acceptable-amount-of-dyno-load
    WARNING

    return <<~EOF
      case $(ulimit -u) in
      256)
        export HEROKU_RAM_LIMIT_MB=${HEROKU_RAM_LIMIT_MB:-512}
        export WEB_CONCURRENCY=${WEB_CONCURRENCY:-2}
        ;;
      512)
        export HEROKU_RAM_LIMIT_MB=${HEROKU_RAM_LIMIT_MB:-1024}
        export WEB_CONCURRENCY=${WEB_CONCURRENCY:-4}
        ;;
      16384)
        export HEROKU_RAM_LIMIT_MB=${HEROKU_RAM_LIMIT_MB:-2560}
        export WEB_CONCURRENCY=${WEB_CONCURRENCY:-8}
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

  # sets up the environment variables for the build process
  def self.setup_language_pack_environment(app_path:, ruby_version:, bundle_default_without:, default_config_vars:, user_env_hash: )
    # By default Node can address 1.5GB of memory, a limitation it inherits from
    # the underlying v8 engine. This can occasionally cause issues during frontend
    # builds where memory use can exceed this threshold.
    #
    # This passes an argument to all Node processes during the build, so that they
    # can take advantage of all available memory on the build dynos.
    ENV["NODE_OPTIONS"] ||= "--max_old_space_size=2560"

    default_config_vars.each do |key, value|
      ENV[key] ||= value
    end

    paths = []
    ENV["GEM_PATH"] = app_path.join(ruby_version.bundler_directory).to_s
    ENV["GEM_HOME"] = ENV["GEM_PATH"]

    ENV["DISABLE_SPRING"] = "1"

    # Rails has a binstub for yarn that doesn't work for all applications
    # we need to ensure that yarn comes before local bin dir for that case
    paths << yarn_preinstall_bin_path if yarn_preinstalled?
    paths << app_path.join("bin").to_s
    paths << app_path.join("vendor/bundle/bin").to_s # Binstubs from bundler, eg. vendor/bundle/bin
    paths << app_path.join(ruby_version.bundler_directory).join("bin").to_s  # Binstubs from rubygems, eg. vendor/bundle/ruby/2.6.0/bin
    paths << ENV["PATH"]

    ENV["PATH"] = paths.join(":")

    ENV["BUNDLE_WITHOUT"] ||= user_env_hash["BUNDLE_WITHOUT"] || bundle_default_without
    if ENV["BUNDLE_WITHOUT"].include?(' ')
      ENV["BUNDLE_WITHOUT"] = ENV["BUNDLE_WITHOUT"].tr(' ', ':')

      warn("Your BUNDLE_WITHOUT contains a space, we are converting it to a colon `:` BUNDLE_WITHOUT=#{ENV["BUNDLE_WITHOUT"]}", inline: true)
    end
    ENV["BUNDLE_PATH"] = "vendor/bundle"
    ENV["BUNDLE_BIN"] = "vendor/bundle/bin"
    ENV["BUNDLE_DEPLOYMENT"] = "1"
  end

  # Sets up the environment variables for subsequent processes run by
  # muiltibuildpack. We can't use profile.d because $HOME isn't set up
  def setup_export(app_path: , ruby_version: , default_config_vars: )
    paths = ENV["PATH"].split(":").map do |path|
      /^\/.*/ !~ path ? "#{app_path}/#{path}" : path
    end.join(":")

    # TODO ensure path exported is correct
    set_export_path "PATH", paths

    gem_path = app_path.join(ruby_version.bundler_directory)
    set_export_path "GEM_PATH", gem_path
    set_export_default "LANG", "en_US.UTF-8"

    # TODO handle jruby
    if ruby_version.jruby?
      set_export_default "JRUBY_OPTS", default_jruby_opts
    end

    set_export_default "BUNDLE_PATH", ENV["BUNDLE_PATH"]
    set_export_default "BUNDLE_WITHOUT", ENV["BUNDLE_WITHOUT"]
    set_export_default "BUNDLE_BIN", ENV["BUNDLE_BIN"]
    set_export_default "BUNDLE_DEPLOYMENT", ENV["BUNDLE_DEPLOYMENT"] # Unset on windows since we delete the Gemfile.lock
    default_config_vars.each do |key, value|
      set_export_default key, value
    end
  end

  # sets up the profile.d script for this buildpack
  def setup_profiled(ruby_layer_path: , gem_layer_path:, ruby_version: , default_config_vars: )
    profiled_path = []

    default_config_vars.each do |key, value|
      set_env_default key, value
    end

    # Rails has a binstub for yarn that doesn't work for all applications
    # we need to ensure that yarn comes before local bin dir for that case
    if yarn_preinstalled?
      profiled_path << yarn_preinstall_bin_path.gsub(File.expand_path("."), "$HOME")
    elsif has_yarn_binary?
      profiled_path << "#{ruby_layer_path}/vendor/#{@yarn_installer.binary_path}"
    end
    profiled_path << "$HOME/bin" # /app in production
    profiled_path << Pathname(gem_layer_path).join("vendor/bundle/bin") # Binstubs from bundler, eg. vendor/bundle/bin
    profiled_path << Pathname(gem_layer_path).join(ruby_version.bundler_directory, "bin") # Binstubs from rubygems, eg. vendor/bundle/ruby/2.6.0/bin
    profiled_path << "$PATH"

    set_env_override "GEM_PATH", [Pathname(gem_layer_path).join(ruby_version.bundler_directory), "$GEM_PATH"].join(":")
    set_env_override "PATH",      profiled_path.join(":")
    set_env_override "DISABLE_SPRING", "1"

    set_env_default "MALLOC_ARENA_MAX", "2"     if default_malloc_arena_max?

    web_concurrency = env("SENSIBLE_DEFAULTS") ? set_default_web_concurrency : ""
    add_to_profiled(web_concurrency, filename: "WEB_CONCURRENCY.sh", mode: "w") # always write that file, even if its empty (meaning no defaults apply), for interop with other buildpacks - and we overwrite the file rather than appending (which is the default)

    # TODO handle JRUBY
    if ruby_version.jruby?
      set_env_default "JRUBY_OPTS", default_jruby_opts
    end

    set_env_default "BUNDLE_PATH", ENV["BUNDLE_PATH"]
    set_env_default "BUNDLE_WITHOUT", ENV["BUNDLE_WITHOUT"]
    set_env_default "BUNDLE_BIN", ENV["BUNDLE_BIN"]
    set_env_default "BUNDLE_DEPLOYMENT", ENV["BUNDLE_DEPLOYMENT"] if ENV["BUNDLE_DEPLOYMENT"] # Unset on windows since we delete the Gemfile.lock
  end

  def warn_outdated_ruby
    return unless defined?(@outdated_version_check)

    @warn_outdated ||= begin
      @outdated_version_check.join

      warn_outdated_minor
      warn_outdated_eol
      warn_stack_upgrade
      true
    end
  end

  def warn_stack_upgrade
    return unless defined?(@ruby_download_check)
    return unless @ruby_download_check.next_stack(current_stack: stack)
    return if @ruby_download_check.exists_on_next_stack?(current_stack: stack)

    warn(<<~WARNING)
      Your Ruby version is not present on the next stack

      You are currently using #{ruby_version.version_for_download} on #{stack} stack.
      This version does not exist on #{@ruby_download_check.next_stack(current_stack: stack)}. In order to upgrade your stack you will
      need to upgrade to a supported Ruby version.

      For a list of supported Ruby versions see:
        https://devcenter.heroku.com/articles/ruby-support#supported-runtimes

      For a list of the oldest Ruby versions present on a given stack see:
        https://devcenter.heroku.com/articles/ruby-support#oldest-available-runtimes
    WARNING
  end

  def warn_outdated_eol
    return unless @outdated_version_check.maybe_eol?

    if @outdated_version_check.eol?
      warn(<<~WARNING)
        EOL Ruby Version

        You are using a Ruby version that has reached its End of Life (EOL)

        We strongly suggest you upgrade to Ruby #{@outdated_version_check.suggest_ruby_eol_version} or later

        Your current Ruby version no longer receives security updates from
        Ruby Core and may have serious vulnerabilities. While you will continue
        to be able to deploy on Heroku with this Ruby version you must upgrade
        to a non-EOL version to be eligible to receive support.

        Upgrade your Ruby version as soon as possible.

        For a list of supported Ruby versions see:
          https://devcenter.heroku.com/articles/ruby-support#supported-runtimes
      WARNING
    else
      # Maybe EOL
      warn(<<~WARNING)
        Potential EOL Ruby Version

        You are using a Ruby version that has either reached its End of Life (EOL)
        or will reach its End of Life on December 25th of this year.

        We suggest you upgrade to Ruby #{@outdated_version_check.suggest_ruby_eol_version} or later

        Once a Ruby version becomes EOL, it will no longer receive
        security updates from Ruby core and may have serious vulnerabilities.

        Please upgrade your Ruby version.

        For a list of supported Ruby versions see:
          https://devcenter.heroku.com/articles/ruby-support#supported-runtimes
      WARNING
    end
  end

  def warn_outdated_minor
    return if @outdated_version_check.latest_minor_version?

    warn(<<~WARNING)
      There is a more recent Ruby version available for you to use:

      #{@outdated_version_check.suggested_ruby_minor_version}

      The latest version will include security and bug fixes. We always recommend
      running the latest version of your minor release.

      Please upgrade your Ruby version.

      For all available Ruby versions see:
        https://devcenter.heroku.com/articles/ruby-support#supported-runtimes
    WARNING
  end

  # install the vendored ruby
  # @return [Boolean] true if it installs the vendored ruby and false otherwise
  def self.install_ruby(app_path: , ruby_version: , stack:, arch: , metadata:, io: )
    # Could do a compare operation to avoid re-downloading ruby
    return false unless ruby_version

    installer = LanguagePack::Installers::HerokuRubyInstaller.new(
      multi_arch_stacks: MULTI_ARCH_STACKS,
      stack: stack,
      arch: arch,
      app_path: app_path,
      env: ENV
    )

    @ruby_download_check = LanguagePack::Helpers::DownloadPresence.new(
      multi_arch_stacks: MULTI_ARCH_STACKS,
      file_name: ruby_version.file_name,
      arch: arch
    )
    @ruby_download_check.call

    installer.install(ruby_version, install_ruby_path(app_path: app_path, ruby_version: ruby_version))

    metadata.write("buildpack_ruby_version", ruby_version.version_for_download)

    io.topic "Using Ruby version: #{ruby_version.version_for_download}"
    if ruby_version.default?
      warn(<<~WARNING)
        You have not declared a Ruby version in your Gemfile.

        To declare a Ruby version add this line to your Gemfile:

        ```
        ruby "#{LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER}"
        ```

        For more information see:
          https://devcenter.heroku.com/articles/ruby-versions
      WARNING
    end

    true
  rescue LanguagePack::Fetcher::FetchError
    if @ruby_download_check.does_not_exist?
      message = <<~ERROR
        The Ruby version you are trying to install does not exist: #{ruby_version.version_for_download}
      ERROR
    else
      message = <<~ERROR
        The Ruby version you are trying to install does not exist on this stack.

        You are trying to install #{ruby_version.version_for_download} on #{stack}.

        Ruby #{ruby_version.version_for_download} is present on the following stacks:

          - #{@ruby_download_check.valid_stack_list.join("\n  - ")}
      ERROR

      if env("CI")
        message << <<~ERROR

          On Heroku CI you can set your stack in the `app.json`. For example:

          ```
          "stack": "heroku-24"
          ```
        ERROR
      end
    end

    message << <<~ERROR

      Heroku recommends you use the latest supported Ruby version listed here:
        https://devcenter.heroku.com/articles/ruby-support#supported-runtimes

      For more information on syntax for declaring a Ruby version see:
        https://devcenter.heroku.com/articles/ruby-versions
    ERROR

    io.error message
  end


  # default set of binaries to install
  # @return [Array] resulting list
  def binaries
    add_node_js_binary + add_yarn_binary
  end

  # vendors binaries into the slug
  def install_binaries
    binaries.each {|binary| install_binary(binary) }
    Dir["bin/*"].each {|path| run("chmod +x #{path}") }
  end

  # vendors individual binary into the slug
  # @param [String] name of the binary package from S3.
  #   Example: https://heroku-buildpack-ruby.s3.us-east-1.amazonaws.com/node-0.4.7.tgz, where name is "node-0.4.7"
  def install_binary(name)
    topic "Installing #{name}"
    bin_dir = "bin"
    FileUtils.mkdir_p bin_dir
    Dir.chdir(bin_dir) do |dir|
      if name.match(/^node\-/)
        @node_installer.install
        # need to set PATH here b/c `node-gyp` can change the CWD, but still depends on executing node.
        # the current PATH is relative, but it needs to be absolute for this.
        # doing this here also prevents it from being exported during runtime
        node_bin_path = File.absolute_path(".")
        # this needs to be set after so other binaries in bin/ don't take precedence"
        ENV["PATH"] = "#{ENV["PATH"]}:#{node_bin_path}"
      elsif name.match(/^yarn\-/)
        FileUtils.mkdir_p("../vendor")
        Dir.chdir("../vendor") do |vendor_dir|
          @yarn_installer.install
          yarn_path = File.absolute_path("#{vendor_dir}/#{@yarn_installer.binary_path}")
          ENV["PATH"] = "#{yarn_path}:#{ENV["PATH"]}"
        end
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

  # remove `vendor/bundle` that comes from the git repo
  # in case there are native ext.
  # users should be using `bundle pack` instead.
  # https://github.com/heroku/heroku-buildpack-ruby/issues/21
  def self.remove_vendor_bundle(app_path: )
    vendor_bundle = app_path.join("vendor").join("bundle")
    if vendor_bundle.exist?
      warn(<<~WARNING)
        Removing `vendor/bundle`.
        Checking in `vendor/bundle` is not supported. Please remove this directory
        and add it to your .gitignore. To vendor your gems with Bundler, use
        `bundle pack` instead.
      WARNING
      vendor_bundle.rmtree
    end
  end

  # runs bundler to install the dependencies
  def self.build_bundler(app_path: , io:, bundler_cache: , bundler_version: , bundler_output: , ruby_version: )
    if app_path.join(".bundle/config").exist?
      warn(<<~WARNING, inline: true)
        You have the `.bundle/config` file checked into your repository
          It contains local state like the location of the installed bundle
          as well as configured git local gems, and other settings that should
        not be shared between multiple checkouts of a single repo. Please
        remove the `.bundle/` folder from your repo and add it to your `.gitignore` file.

        https://devcenter.heroku.com/articles/bundler-configuration
      WARNING
    end

    bundle_command = String.new("")
    bundle_command << "BUNDLE_WITHOUT='#{ENV["BUNDLE_WITHOUT"]}' "
    bundle_command << "BUNDLE_PATH=#{ENV["BUNDLE_PATH"]} "
    bundle_command << "BUNDLE_BIN=#{ENV["BUNDLE_BIN"]} "
    bundle_command << "BUNDLE_DEPLOYMENT=#{ENV["BUNDLE_DEPLOYMENT"]} " if ENV["BUNDLE_DEPLOYMENT"] # Unset on windows since we delete the Gemfile.lock
    bundle_command << "bundle install -j4"

    io.topic("Installing dependencies using bundler #{bundler_version}")

    bundle_time = nil
    env_vars = {}

    env_vars["BUNDLE_GEMFILE"] = app_path.join("Gemfile").to_s
    env_vars["BUNDLE_CONFIG"] = app_path.join("/.bundle/config").to_s
    env_vars["NOKOGIRI_USE_SYSTEM_LIBRARIES"] = "true"
    env_vars["BUNDLE_DISABLE_VERSION_CHECK"] = "true"

    io.puts "Running: #{bundle_command}"
    bundle_time = Benchmark.realtime do
      bundler_output << pipe("#{bundle_command} --no-clean", out: "2>&1", env: env_vars, user_env: true)
    end

    if $?.success?
      io.puts "Bundle completed (#{"%.2f" % bundle_time}s)"
      io.puts "Cleaning up the bundler cache."
      pipe("bundle clean", out: "2> /dev/null", user_env: true, env: env_vars)
      bundler_cache.store

      # Keep gem cache out of the slug
      app_path.join(ruby_version.bundler_directory).join("cache").rmtree
    else
      error_message = "Failed to install gems via Bundler."
      io.puts "Bundler Output: #{bundler_output}"
      if bundler_output.match(/An error occurred while installing sqlite3/)
        error_message += <<~ERROR

          Detected sqlite3 gem which is not supported on Heroku:
          https://devcenter.heroku.com/articles/sqlite3
        ERROR
      end

      if bundler_output.match(/but your Gemfile specified/)
        error_message += <<~ERROR

          Detected a mismatch between your Ruby version installed and
          Ruby version specified in Gemfile or Gemfile.lock. You can
          correct this by running:

              $ bundle update --ruby
              $ git add Gemfile.lock
              $ git commit -m "update ruby version"

          If this does not solve the issue please see this documentation:

          https://devcenter.heroku.com/articles/ruby-versions#your-ruby-version-is-x-but-your-gemfile-specified-y
        ERROR
      end

      io.error error_message
    end
  end

  def post_bundler(ruby_version: , app_path: )
    Dir[app_path.join(ruby_version.bundler_directory, "**", ".git")].each do |dir|
      FileUtils.rm_rf(dir)
    end
    bundler.clean
  end

  def rake
    @rake ||= begin
      raise_on_fail = bundler.gem_version('railties') && bundler.gem_version('railties') > Gem::Version.new('3.x')

      topic "Detecting rake tasks"
      rake = LanguagePack::Helpers::RakeRunner.new
      rake.load_rake_tasks!({ env: rake_env }, raise_on_fail)
      rake
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

  # decides if we need to enable the dev database addon
  # @return [Array] the database addon if the pg gem is detected or an empty Array if it isn't.
  def add_dev_database_addon
    return [] if env("HEROKU_SKIP_DATABASE_PROVISION")

    [
      "pg",
      "activerecord-jdbcpostgresql-adapter",
      "jdbc-postgres",
      "jdbc-postgresql",
      "jruby-pg",
      "rjack-jdbc-postgres",
      "tgbyte-activerecord-jdbcpostgresql-adapter"
    ].any? {|a| bundler.has_gem?(a) } ? ['heroku-postgresql'] : []
  end

  # decides if we need to install the node.js binary
  # @note execjs will blow up if no JS RUNTIME is detected and is loaded.
  # @return [Array] the node.js binary path if we need it or an empty Array
  def add_node_js_binary
    return [] if node_js_preinstalled?

    if Pathname(app_path).join("package.json").exist? ||
         bundler.has_gem?('execjs') ||
         bundler.has_gem?('webpacker')

      version = @node_installer.version
      old_version = @metadata.fetch("default_node_version") { version }

      # Make available for `rake assets:precompile` and other sub-shells
      ENV["UV_USE_IO_URING"] ||= "0"
      # Make available to future buildpacks (export), but not runtime (profile.d)
      set_export_default "UV_USE_IO_URING", "0"

      if version != version
        warn(<<~WARNING, inline: true)
          Default version of Node.js changed (#{old_version} to #{version})
        WARNING
      end

      warn(<<~WARNING, inline: true)
        Installing a default version (#{version}) of Node.js.
        This version is not pinned and can change over time, causing unexpected failures.

        Heroku recommends placing the `heroku/nodejs` buildpack in front of
        `heroku/ruby` to install a specific version of node:

        https://devcenter.heroku.com/articles/ruby-support#node-js-support
      WARNING

      [@node_installer.binary_path]
    else
      []
    end
  end

  def add_yarn_binary
    return [] if yarn_preinstalled?

    if Pathname(app_path).join("yarn.lock").exist? || bundler.has_gem?('webpacker')

      version = @yarn_installer.version
      old_version = @metadata.fetch("default_yarn_version") { version }

      # Make available for `rake assets:precompile` and other sub-shells
      ENV["UV_USE_IO_URING"] ||= "0"
      # Make available to future buildpacks (export), but not runtime (profile.d)
      set_export_default "UV_USE_IO_URING", "0"

      if version != version
        warn(<<~WARNING, inline: true)
          Default version of Yarn changed (#{old_version} to #{version})
        WARNING
      end

      warn(<<~WARNING, inline: true)
        Installing a default version (#{version}) of Yarn
        This version is not pinned and can change over time, causing unexpected failures.

        Heroku recommends placing the `heroku/nodejs` buildpack in front of the `heroku/ruby`
        buildpack as it offers more comprehensive Node.js support, including the ability to
        customise the Node.js version:

        https://devcenter.heroku.com/articles/ruby-support#node-js-support
      WARNING

      [@yarn_installer.name]
    else
      []
    end
  end

  def has_yarn_binary?
    add_yarn_binary.any?
  end

  # checks if node.js is installed via the official heroku-buildpack-nodejs using multibuildpack
  # @return String if it's detected and false if it isn't
  def node_preinstall_bin_path
    return @node_preinstall_bin_path if defined?(@node_preinstall_bin_path)

    legacy_path = "#{Dir.pwd}/#{NODE_BP_PATH}"
    path        = run("which node").strip
    if path && $?.success?
      @node_preinstall_bin_path = path
    elsif run("#{legacy_path}/node -v") && $?.success?
      @node_preinstall_bin_path = legacy_path
    else
      @node_preinstall_bin_path = false
    end
  end
  alias :node_js_preinstalled? :node_preinstall_bin_path

  def node_not_preinstalled?
    !node_js_preinstalled?
  end

  def yarn_preinstall_bin_path
    LanguagePack::Ruby.yarn_preinstall_bin_path
  end

  # Example: tmp/build_8523f77fb96a956101d00988dfeed9d4/.heroku/yarn/bin/ (without the `yarn` at the end)
  def self.yarn_preinstall_bin_path
    (yarn_preinstall_binary_path || "").chomp("/yarn")
  end

  # Example `tmp/build_8523f77fb96a956101d00988dfeed9d4/.heroku/yarn/bin/yarn`
  def self.yarn_preinstall_binary_path
    return @yarn_preinstall_binary_path if defined?(@yarn_preinstall_binary_path)

    path = run("which yarn").strip
    if path && $?.success?
      @yarn_preinstall_binary_path = path
    else
      @yarn_preinstall_binary_path = false
    end
  end

  def yarn_preinstalled?
    LanguagePack::Ruby.yarn_preinstalled?
  end

  def self.yarn_preinstalled?
    self.yarn_preinstall_binary_path
  end

  def run_assets_precompile_rake_task
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

  def precompile_fail(output)
    msg = "Precompiling assets failed.\n"
    if output.match(/(127\.0\.0\.1)|(org\.postgresql\.util)/)
      msg << "Attempted to access a nonexistent database:\n"
      msg << "https://devcenter.heroku.com/articles/pre-provision-database\n"
    end

    sprockets_version = bundler.gem_version('sprockets')
    if output.match(/Sprockets::FileNotFound/) && (sprockets_version < Gem::Version.new('4.0.0.beta7') && sprockets_version > Gem::Version.new('4.0.0.beta4'))
      msg << "If you have this file in your project\n"
      msg << "try upgrading to Sprockets 4.0.0.beta7 or later:\n"
      msg << "https://github.com/rails/sprockets/pull/547\n"
    end

    error msg
  end

  def self.load_bundler_cache(cache: , metadata: , stack:, bundler_cache: , bundler_version:, bundler:, io: , new_app:, ruby_version: )
    cache.load "vendor"

    full_ruby_version = `ruby -v 2>/dev/null`.strip
    ruby_version_cache = "ruby_version"
    stack_cache = "stack"

    # bundle clean does not remove binstubs
    FileUtils.rm_rf("vendor/bundler/bin")

    old_stack = metadata.try_read(stack_cache)

    stack_change  = old_stack != stack
    convert_stack = bundler_cache.old?
    bundler_cache.convert_stack(stack_change) if convert_stack
    if !new_app && stack_change
      io.puts "Purging Cache. Changing stack from #{old_stack} to #{stack}"
      purge_bundler_cache(bundler_cache: bundler_cache, stack: old_stack, ruby_version: ruby_version, bundler: bundler)
    elsif !new_app && !convert_stack
      bundler_cache.load
    end

    if (bundler_cache.exists? || bundler_cache.old?) &&
        metadata.exists?(ruby_version_cache) &&
        full_ruby_version != metadata.read(ruby_version_cache).strip
      io.puts "Ruby version change detected. Clearing bundler cache."
      io.puts "Old: #{metadata.read(ruby_version_cache).strip}"
      io.puts "New: #{full_ruby_version}"
      purge_bundler_cache(bundler_cache: bundler_cache, stack: nil, ruby_version: ruby_version, bundler: bundler)
    end

    metadata.write(ruby_version_cache, full_ruby_version)
    metadata.write("buildpack_version", BUILDPACK_VERSION)
    metadata.write("bundler_version", bundler_version)
    metadata.write("rubygems_version", `gem -v 2>/dev/null`.strip)
    metadata.write(stack_cache, stack)
  end

  def self.purge_bundler_cache(bundler_cache: , stack:  nil, ruby_version: , bundler:)
    bundler_cache.clear(stack)
    # need to reinstall bundler
    bundler.install
  end

  def purge_bundler_cache(stack = nil)
    @bundler_cache.clear(stack)
    bundler.install
  end

  # writes ERB based database.yml for Rails. The database.yml uses the DATABASE_URL from the environment during runtime.
  def create_database_yml
    return false unless File.directory?("config")
    return false if  bundler.has_gem?('activerecord') && bundler.gem_version('activerecord') >= Gem::Version.new('4.1.0.beta1')

    topic("Writing config/database.yml to read from DATABASE_URL")
    File.open("config/database.yml", "w") do |file|
      file.puts <<~DATABASE_YML
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
