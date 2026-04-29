require_relative "../spec_helper"

describe LanguagePack::Helpers::BundleBinstubCheck do
  def make_warn_obj
    warn_obj = Object.new
    def warn_obj.warn(*args, **kwargs)
      @msg = args.first
    end

    def warn_obj.msg
      @msg
    end

    warn_obj
  end

  it "warns when bin/bundle exists" do
    Dir.mktmpdir do |dir|
      bin_dir = Pathname.new(dir).join("bin")
      bin_dir.mkpath
      bin_dir.join("bundle").write("#!/usr/bin/env ruby\n")

      warn_obj = make_warn_obj
      check = LanguagePack::Helpers::BundleBinstubCheck.new(
        app_root_dir: dir,
        warn_object: warn_obj
      )

      expect(check.call).to eq(true)
      expect(warn_obj.msg).to include("bin/bundle")
      expect(warn_obj.msg).to include("rm bin/bundle")
    end
  end

  it "does not warn when bin/bundle does not exist" do
    Dir.mktmpdir do |dir|
      bin_dir = Pathname.new(dir).join("bin")
      bin_dir.mkpath
      bin_dir.join("rails").write("#!/usr/bin/env ruby\n")

      warn_obj = make_warn_obj
      check = LanguagePack::Helpers::BundleBinstubCheck.new(
        app_root_dir: dir,
        warn_object: warn_obj
      )

      expect(check.call).to eq(false)
      expect(warn_obj.msg).to be_nil
    end
  end

  it "does not warn when bin directory does not exist" do
    Dir.mktmpdir do |dir|
      warn_obj = make_warn_obj
      check = LanguagePack::Helpers::BundleBinstubCheck.new(
        app_root_dir: dir,
        warn_object: warn_obj
      )

      expect(check.call).to eq(false)
      expect(warn_obj.msg).to be_nil
    end
  end
end
