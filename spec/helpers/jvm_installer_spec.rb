require 'spec_helper'

describe "JvmInstall" do

  it "downloads custom JDK" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        begin
          ENV['JDK_URL_1_8'] = "http://lang-jvm.s3.amazonaws.com/jdk/openjdk1.8.0_51-cedar14.tar.gz"

          jvm_installer = LanguagePack::JvmInstaller.new(dir, "cedar-14")
          jvm_installer.install("9.0.1.0")

          expect(`ls bin`).to match("java")
          expect(`cat release 2>&1`).to match("1.8.0_51")
        ensure
          ENV['JDK_URL_1_8'] = nil
        end
      end
    end
  end

  it "downloads standard JDK 7" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.open('system.properties', 'w') { |f| f.write("java.runtime.version=1.7") }

        jvm_installer = LanguagePack::JvmInstaller.new(dir, "cedar-14")
        jvm_installer.install("9.0.1.0")

        expect(`ls bin`).to match("java")
        expect(`cat release 2>&1`).not_to match("1.8.0")
        expect(`cat release 2>&1`).to match("1.7.0")
      end
    end
  end

  it "downloads standard JDK 9" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.open('system.properties', 'w') { |f| f.write("java.runtime.version=1.9") }

        jvm_installer = LanguagePack::JvmInstaller.new(dir, "cedar-14")
        jvm_installer.install("9.0.1.0")

        expect(`ls bin`).to match("java")
        expect(`cat release 2>&1`).not_to match("1.8.0")
        expect(`cat release 2>&1`).to match("1.9.0")
      end
    end
  end

  it "downloads previous JDK version" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.open('system.properties', 'w') { |f| f.write("java.runtime.version=1.8.0_51") }

        jvm_installer = LanguagePack::JvmInstaller.new(dir, "cedar-14")
        jvm_installer.install("9.0.1.0")

        expect(`ls bin`).to match("java")
        expect(`cat release 2>&1`).to match("1.8.0_51")
      end
    end
  end

  it "downloads default JDK" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        jvm_installer = LanguagePack::JvmInstaller.new(dir, "cedar-14")
        jvm_installer.install("9.0.1.0")

        expect(`ls bin`).to match("java")
        expect(`cat release 2>&1`).not_to match("1.8.0_51")
        expect(`cat release 2>&1`).to match("1.8.0")
      end
    end
  end

  it "fails download gracefully" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.open('system.properties', 'w') { |f| f.write("java.runtime.version=foobar") }

        jvm_installer = LanguagePack::JvmInstaller.new(dir, "cedar-14")

        expect{ jvm_installer.install("9.0.1.0") }.to raise_error(BuildpackError)
      end
    end
  end
end
