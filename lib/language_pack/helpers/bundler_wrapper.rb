class LanguagePack::Helpers::BundlerWrapper
  include LanguagePack::ShellHelpers

  class GemfileParseError < BuildpackError
    def initialize(error)
      msg = "There was an error parsing your Gemfile, we cannot continue\n"
      msg << error
      super msg
    end
  end

  VENDOR_URL         = LanguagePack::Base::VENDOR_URL                # coupling
  DEFAULT_FETCHER    = LanguagePack::Fetcher.new(VENDOR_URL)         # coupling
  BUNDLER_DIR_NAME   = LanguagePack::Ruby::BUNDLER_GEM_PATH          # coupling
  BUNDLER_PATH       = File.expand_path("../../../../tmp/#{BUNDLER_DIR_NAME}", __FILE__)
  GEMFILE_PATH       = Pathname.new "./Gemfile"

  attr_reader   :bundler_path

  def initialize(options = {})
    @fetcher              = options[:fetcher]      || DEFAULT_FETCHER
    @bundler_tmp          = Dir.mktmpdir
    @bundler_path         = options[:bundler_path] || File.join(@bundler_tmp, "#{BUNDLER_DIR_NAME}")
    @gemfile_path         = options[:gemfile_path] || GEMFILE_PATH
    @bundler_tar          = options[:bundler_tar]  || "#{BUNDLER_DIR_NAME}.tgz"
    @gemfile_lock_path    = "#{@gemfile_path}.lock"
    @orig_bundle_gemfile  = ENV['BUNDLE_GEMFILE']
    ENV['BUNDLE_GEMFILE'] = @gemfile_path.to_s
    @path                 = Pathname.new "#{@bundler_path}/gems/#{BUNDLER_DIR_NAME}/lib"
  end

  def install
    fetch_bundler
    $LOAD_PATH << @path
    require "bundler"
    self
  end

  def clean
    ENV['BUNDLE_GEMFILE'] = @orig_bundle_gemfile
    FileUtils.remove_entry_secure(@bundler_tmp) if Dir.exist?(@bundler_tmp)

    if LanguagePack::Ruby::BUNDLER_VERSION  == "1.7.12"
      # Hack to cleanup after pre 1.8 versions of bundler. See https://github.com/bundler/bundler/pull/3277/
      Dir["#{Dir.tmpdir}/bundler*"].each do |dir|
        FileUtils.remove_entry_secure(dir) if Dir.exist?(dir) && File.stat(dir).writable?
      end
    end
  end

  def has_gem?(name)
    specs.key?(name)
  end

  def gem_version(name)
    instrument "ruby.gem_version" do
      if spec = specs[name]
        spec.version
      end
    end
  end

  # detects whether the Gemfile.lock contains the Windows platform
  # @return [Boolean] true if the Gemfile.lock was created on Windows
  def windows_gemfile_lock?
    platforms.detect do |platform|
      /mingw|mswin/.match(platform.os) if platform.is_a?(Gem::Platform)
    end
  end

  def specs
    @specs     ||= lockfile_parser.specs.each_with_object({}) {|spec, hash| hash[spec.name] = spec }
  end

  def platforms
    @platforms ||= lockfile_parser.platforms
  end

  def version
    Bundler::VERSION
  end

  def instrument(*args, &block)
    LanguagePack::Instrument.instrument(*args, &block)
  end

  def ruby_version
    instrument 'detect_ruby_version' do
      env = { "PATH"     => "#{bundler_path}/bin:#{ENV['PATH']}",
              "RUBYLIB"  => File.join(bundler_path, "gems", BUNDLER_DIR_NAME, "lib"),
              "GEM_PATH" => "#{bundler_path}:#{ENV["GEM_PATH"]}"
            }
      command = "bundle platform --ruby"

      # Silently check for ruby version
      output  = run_stdout(command, user_env: true, env: env)

      # If there's a gem in the Gemfile (i.e. syntax error) emit error
      raise GemfileParseError.new(run("bundle check", user_env: true, env: env)) unless $?.success?
      if output.match(/No ruby version specified/)
        ""
      else
        output.chomp.sub('(', '').sub(')', '').sub(/(p\d+)/, ' \1').split.join('-')
      end
    end
  end

  def lockfile_parser
    @lockfile_parser ||= parse_gemfile_lock
  end

  private
  def fetch_bundler
    instrument 'fetch_bundler' do
      return true if Dir.exists?(bundler_path)
      FileUtils.mkdir_p(bundler_path)
      Dir.chdir(bundler_path) do
        @fetcher.fetch_untar(@bundler_tar)
      end
      Dir["bin/*"].each {|path| `chmod 755 #{path}` }
    end
  end

  def parse_gemfile_lock
    instrument 'parse_bundle' do
      gemfile_contents = File.read(@gemfile_lock_path)
      Bundler::LockfileParser.new(gemfile_contents)
    end
  end
end
