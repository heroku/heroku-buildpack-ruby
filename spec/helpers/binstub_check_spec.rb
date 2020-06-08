require_relative "../spec_helper.rb"

describe LanguagePack::Helpers::BinstubCheck do
  it "doesn't error on empty directories" do
    Dir.mktmpdir do |dir|
      warn_obj = Object.new
      check = LanguagePack::Helpers::BinstubCheck.new(app_root_dir: dir, warn_object: warn_obj)
      check.call
    end
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
