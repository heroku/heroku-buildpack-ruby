require_relative "../spec_helper.rb"

describe LanguagePack::Helpers::BinstubCheck do
  def get_ruby_path!
    out = `which ruby`.strip
    raise "command `which ruby` failed with output: #{out}" unless $?.success?

    return Pathname.new(out)
  end

  def get_ruby_bin_dir!
    ruby_bin_dir = get_ruby_path!.join("..")
    raise "#{ruby_bin_dir} is not a directory" unless File.directory?(ruby_bin_dir)

    return ruby_bin_dir
  end

  it "handles empty binstubs" do
    Tempfile.create("foo.txt") do |f|
      expect { Pathname.new(f).open(&:readline) }.to raise_error(EOFError)

      binstub = LanguagePack::Helpers::BinstubWrapper.new(f.path)
      expect(binstub.bad_shebang?).to be_falsey
      expect(binstub.binary?).to be_falsey
    end
  end

  it "can determine if a file is binary or not" do
    binstub = LanguagePack::Helpers::BinstubWrapper.new(get_ruby_path!)

    expect(binstub.bad_shebang?).to be_falsey
    expect(binstub.binary?).to be_truthy

    Tempfile.create("foo.txt") do |f|
      f.write("foo")
      f.close
      binstub = LanguagePack::Helpers::BinstubWrapper.new(f.path)

      expect(binstub.bad_shebang?).to be_falsey
      expect(binstub.binary?).to be_falsey
    end
  end

  it "doesn't error on empty directories" do
    Dir.mktmpdir do |dir|
      warn_obj = Object.new
      check = LanguagePack::Helpers::BinstubCheck.new(app_root_dir: dir, warn_object: warn_obj)
      check.call
    end
  end

  it "does not raise an error when running against a directory with a binary file in it" do
    ruby_bin_dir = get_ruby_bin_dir!
    check = LanguagePack::Helpers::BinstubCheck.new(app_root_dir: ruby_bin_dir, warn_object: Object.new)
    check.call
  end

  it "checks binstubs and finds bad ones" do
    Dir.mktmpdir do |dir|
      bin_dir = Pathname.new(dir).join("bin")
      bin_dir.mkpath

      # Bad binstub
      bin_dir.join("bad_binstub_example").write(<<~EOM)
        #!/usr/bin/env ruby2.5

        nothing else matters
      EOM

      # Good binstub
      bin_dir.join("good_binstub_example").write(<<~EOM)
        #!/usr/bin/env bash

        nothing else matters
      EOM
      bin_dir.join("good_binstub_example_two").write("#!/usr/bin/env ruby")

      warn_obj = Object.new
      def warn_obj.warn(*args, **kwargs); @msg = args.first; end
      def warn_obj.msg; @msg; end

      check = LanguagePack::Helpers::BinstubCheck.new(app_root_dir: dir, warn_object: warn_obj)
      check.call

      expect(check.bad_binstubs.count).to eq(1)
      expect(warn_obj.msg).to include("bin/bad_binstub_example")
    end
  end
end
