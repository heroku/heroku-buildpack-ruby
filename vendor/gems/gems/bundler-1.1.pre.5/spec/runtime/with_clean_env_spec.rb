require "spec_helper"

describe "Bundler.with_env helpers" do

  shared_examples_for "Bundler.with_*_env" do
    it "should reset and restore the environment" do
      gem_path = ENV['GEM_PATH']

      Bundler.with_clean_env do
        `echo $GEM_PATH`.strip.should_not == gem_path
      end

      ENV['GEM_PATH'].should == gem_path
    end
  end

  around do |example|
    bundle_path = Bundler::ORIGINAL_ENV['BUNDLE_PATH']
    Bundler::ORIGINAL_ENV['BUNDLE_PATH'] = "./Gemfile"
    example.run
    Bundler::ORIGINAL_ENV['BUNDLE_PATH'] = bundle_path
  end

  describe "Bundler.with_clean_env" do

    it_should_behave_like "Bundler.with_*_env"

    it "should not pass any bundler environment variables" do
      Bundler.with_clean_env do
        `echo $BUNDLE_PATH`.strip.should_not == './Gemfile'
      end
    end

    it "should not change ORIGINAL_ENV" do
      Bundler::ORIGINAL_ENV['BUNDLE_PATH'].should == './Gemfile'
    end

  end

  describe "Bundler.with_original_env" do

    it_should_behave_like "Bundler.with_*_env"

    it "should pass bundler environment variables set before Bundler was run" do
      Bundler.with_original_env do
        `echo $BUNDLE_PATH`.strip.should == './Gemfile'
      end
    end
  end

  describe "Bundler.clean_system" do
    it "runs system inside with_clean_env" do
      Bundler.clean_system(%{echo 'if [ "$BUNDLE_PATH" = "" ]; then exit 42; else exit 1; fi' | /bin/sh})
      $?.exitstatus.should == 42
    end
  end

  describe "Bundler.clean_exec" do
    it "runs exec inside with_clean_env" do
      pid = Kernel.fork do
        Bundler.clean_exec(%{echo 'if [ "$BUNDLE_PATH" = "" ]; then exit 42; else exit 1; fi' | /bin/sh})
      end
      Process.wait(pid)
      $?.exitstatus.should == 42
    end
  end

end
