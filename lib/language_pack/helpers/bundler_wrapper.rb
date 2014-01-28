class LanguagePack::Helpers::BundlerWrapper
  class GemfileParseError < StandardError
    def initialize(error)
      msg = "There was an error parsing your Gemfile, we cannot continue\n"
      msg << error.message
      self.set_backtrace(error.backtrace)
      super msg
    end
  end

  DEFAULT_FETCHER  = LanguagePack::Fetcher.new(LanguagePack::Base::VENDOR_URL)
  BUNDLER_DIR_NAME = LanguagePack::Ruby::BUNDLER_DIR_NAME

  def initialize(options = {})
    @unlock               = false
    @install_into         = options[:install_into] || Dir.mktmpdir
    @fetcher              = options[:fetcher]      || DEFAULT_FETCHER
    @bundler_tar          = options[:bundler_tar]  || "#{BUNDLER_DIR_NAME}.tgz"
    @gemfile_path         = options[:gemfile_path] || "./Gemfile"

    @lib_path             = Pathname.new "#{@install_into}/gems/#{BUNDLER_DIR_NAME}/lib"
    @orig_gemfile_path    = ENV['BUNDLE_GEMFILE']
    ENV['BUNDLE_GEMFILE'] = @gemfile_path
  end

  def copy_into(path)
    FileUtils.cp_r(@install_into, File.join(path, BUNDLER_DIR_NAME))
  end

  def gemfile_lock_path
    "#{@gemfile_path}.lock"
  end

  def install
    fetch_bundler
    $LOAD_PATH << @lib_path
    without_warnings do
      load @lib_path.join("bundler.rb")
    end
    return self
  end

  def clean
    ENV['BUNDLE_GEMFILE'] = @orig_gemfile_path
    FileUtils.remove_entry_secure(@install_into) if Dir.exist?(@install_into)
  end

  def without_warnings(&block)
    orig_verb  = $VERBOSE
    $VERBOSE   = nil
    yield
  ensure
    $VERBOSE = orig_verb
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

  def ui
    Bundler.ui = Bundler::UI::Shell.new({})
  end

  def definition
    Bundler.definition(@unlock)
  rescue => e
    raise GemfileParseError.new(e)
  end

  def unlock
    @unlock = true
    yield
  ensure
    @unlock = false
  end

  def ruby_version
    unlock do
      definition.ruby_version
    end
  end

  def lockfile_parser
    @lockfile_parser ||= parse_gemfile_lock
  end

  private
  def fetch_bundler
    instrument 'fetch_bundler' do
      Dir.chdir(@install_into) do
        @fetcher.fetch_untar(@bundler_tar)
      end
    end
  end

  def parse_gemfile_lock
    instrument 'parse_bundle' do
      gemfile_contents = File.read(gemfile_lock_path)
      Bundler::LockfileParser.new(gemfile_contents)
    end
  end
end
