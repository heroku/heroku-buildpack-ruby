require 'spec_helper'

describe "JvmInstall" do

  it "downloads custom JDK" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        ENV['JDK_URL_1_8'] = "http://lang-jvm.s3.amazonaws.com/jdk/openjdk1.8.0_51-cedar14.tar.gz"

        jvm_installer = LanguagePack::JvmInstaller.new(dir, @stack)
        jvm_installer.install("1.8")

        expect(`ls bin`).to match("java")
        expect(`cat release 2>&1`).to match("1.8.0_51")
      end
    end
  end

  it "downloads standard JDK" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        ENV['JDK_URL_1_8'] = nil

        jvm_installer = LanguagePack::JvmInstaller.new(dir, @stack)
        jvm_installer.install("1.8")

        expect(`ls bin`).to match("java")
        expect(`cat release 2>&1`).not_to match("1.8.0_51")
        expect(`cat release 2>&1`).to match("1.8.0")
      end
    end
  end
end
