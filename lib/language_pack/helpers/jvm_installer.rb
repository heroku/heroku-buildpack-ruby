require "language_pack/shell_helpers"

class LanguagePack::JvmInstaller
  include LanguagePack::ShellHelpers

  SYS_PROPS_FILE  = "system.properties"
  JVM_BASE_URL    = "http://lang-jvm.s3.amazonaws.com/jdk"
  JVM_1_8_PATH    = "openjdk1.8-latest"
  JVM_1_7_PATH    = "openjdk1.7-latest"
  JVM_1_7_25_PATH = "openjdk1.7.0_25"
  JVM_1_6_PATH    = "openjdk1.6-latest"

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
    jvm_version =
      case system_properties['java.runtime.version']
      when "1.8"
        JVM_1_8_PATH
      when "1.7"
        JVM_1_7_PATH
      when "1.6"
        JVM_1_6_PATH
      else
        if @stack == "cedar"
          if forced || Gem::Version.new(jruby_version) >= Gem::Version.new("1.7.4")
            JVM_1_7_PATH
          else
            JVM_1_7_25_PATH
          end
        else
          JVM_1_8_PATH
        end
      end

    topic "Installing JVM: #{jvm_version}"

    FileUtils.mkdir_p(@vendor_dir)
    Dir.chdir(@vendor_dir) do
      @fetcher.fetch_untar("#{jvm_version}.tar.gz")
    end

    bin_dir = "bin"
    FileUtils.mkdir_p bin_dir
    Dir["#{@vendor_dir}/bin/*"].each do |bin|
      run("ln -s ../#{bin} #{bin_dir}")
    end
  end
end
