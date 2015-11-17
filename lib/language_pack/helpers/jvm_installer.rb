require "language_pack/shell_helpers"

class LanguagePack::JvmInstaller
  include LanguagePack::ShellHelpers

  SYS_PROPS_FILE  = "system.properties"
  JVM_BASE_URL    = "https://lang-jvm.s3.amazonaws.com/jdk"
  JVM_1_9_PATH    = "openjdk1.9-latest.tar.gz"
  JVM_1_8_PATH    = "openjdk1.8-latest.tar.gz"
  JVM_1_7_PATH    = "openjdk1.7-latest.tar.gz"
  JVM_1_7_25_PATH = "openjdk1.7.0_25.tar.gz"
  JVM_1_6_PATH    = "openjdk1.6-latest.tar.gz"

  def initialize(slug_vendor_jvm, stack)
    @vendor_dir = slug_vendor_jvm
    @stack = stack
    @fetcher = LanguagePack::Fetcher.new(JVM_BASE_URL, stack)
  end

  def system_properties
    props = {}
    File.read(SYS_PROPS_FILE).split("\n").each do |line|
      key = line.split("=").first
      val = line.split("=").last
      props[key] = val
    end if File.exists?(SYS_PROPS_FILE)
    props
  end

  def install(jruby_version, forced = false)
    if Dir.exist?(".jdk")
      topic "Using pre-installed JDK"
      return
    end

    jvm_version = system_properties['java.runtime.version']
    case jvm_version
    when "1.9", "9"
      fetch_env_untar('JDK_URL_1_9') || fetch_untar(JVM_1_9_PATH, "openjdk-9")
    when "1.7", "7"
      fetch_env_untar('JDK_URL_1_7') || fetch_untar(JVM_1_7_PATH, "openjdk-7")
    when "1.6", "6"
      fetch_env_untar('JDK_URL_1_6') || fetch_untar(JVM_1_6_PATH, "openjdk-6")
    when nil
      if @stack == "cedar"
        if forced || Gem::Version.new(jruby_version) >= Gem::Version.new("1.7.4")
          fetch_untar(JVM_1_7_PATH, "openjdk-7")
        else
          fetch_untar(JVM_1_7_25_PATH)
        end
      else
      fetch_env_untar('JDK_URL_1_8') || fetch_untar(JVM_1_8_PATH, "openjdk-8")
      end
    else
      fetch_untar("openjdk#{jvm_version}.tar.gz", "openjdk-#{jvm_version}")
    end

    bin_dir = "bin"
    FileUtils.mkdir_p bin_dir
    Dir["#{@vendor_dir}/bin/*"].each do |bin|
      run("ln -s ../#{bin} #{bin_dir}")
    end
  end

  def fetch_untar(jvm_path, jvm_version=nil)
    topic "Installing JVM: #{jvm_version || jvm_path}"

    FileUtils.mkdir_p(@vendor_dir)
    Dir.chdir(@vendor_dir) do
      @fetcher.fetch_untar(jvm_path)
    end
  rescue LanguagePack::Fetcher::FetchError
    error <<EOF
Failed to download JVM: #{jvm_path}

If this was a custom version or URL, please check to ensure it is correct.
Otherwise, please open a ticket at http://help.heroku.com so we can help.
EOF
  end

  def fetch_env_untar(key)
    val = env(key)
    return false unless val
    path = Pathname.new(val)
    jvm_version = path.basename.to_s
    base_url = val[0, val.index(jvm_version)]
    @fetcher =  LanguagePack::Fetcher.new(base_url)
    fetch_untar(jvm_version)
    true
  end
end
