require 'spec_helper'

describe LanguagePack::Helpers::FsExtra::Copy do
  it "copies a file" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      from_path.join("file.txt").write("from")
      LanguagePack::Helpers::FsExtra::Copy.new(
        from_path: from_path,
        to_path: to_path,
        overwrite: true
      ).call
      expect(to_path.join("file.txt").read).to eq("from")
    end
  end

  it "copies a directory" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)
      from_path.join("file.txt").write("from")
      LanguagePack::Helpers::FsExtra::Copy.new(
        from_path: from_path,
        to_path: to_path,
        overwrite: true
      ).call
      expect(to_path.join("file.txt").read).to eq("from")
    end
  end

  it "copies a directory and replaces existing files when overwrite is true" do
    Dir.mktmpdir do |dir|
      filename = "file.txt"
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)
      from_path.join(filename).write("replacement contents")
      to_path.join(filename).write("original contents")
      LanguagePack::Helpers::FsExtra::Copy.new(
        from_path: from_path,
        to_path: to_path,
        overwrite: true
      ).call

      expect(to_path.join(filename).read).to eq("replacement contents")
    end
  end

  it "copies a directory and does not replace existing files when overwrite is false" do
    Dir.mktmpdir do |dir|
      filename = "file.txt"
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)
      from_path.join(filename).write("replacement contents")
      to_path.join(filename).write("original contents")
      LanguagePack::Helpers::FsExtra::Copy.new(
        from_path: from_path,
        to_path: to_path,
        overwrite: false
      ).call
      expect(to_path.join(filename).read).to eq("original contents")
    end
  end

  it "copies a directory with symlinks when overwrite is true" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      from_path.join("realfile.txt").write("file contents")
      from_path.join("symlink.txt").make_symlink(from_path.join("realfile.txt"))

      expect(from_path.join("symlink.txt").read).to eq("file contents")
      expect(from_path.join("symlink.txt").symlink?).to be(true)

      LanguagePack::Helpers::FsExtra::Copy.new(
        from_path: from_path,
        to_path: to_path,
        overwrite: true
      ).call

      expect(to_path.join("symlink.txt").read).to eq("file contents")
      expect(to_path.join("symlink.txt").symlink?).to be(true)
    end
  end

  it "copies a directory with symlinks when overwrite is false" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").join("subdir").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      from_path.join("realfile.txt").write("file contents")
      from_path.join("symlink.txt").make_symlink(from_path.join("realfile.txt"))

      expect(from_path.join("symlink.txt").read).to eq("file contents")
      expect(from_path.join("symlink.txt").symlink?).to be(true)

      LanguagePack::Helpers::FsExtra::Copy.new(
        from_path: from_path,
        to_path: to_path,
        overwrite: false
      ).call

      expect(to_path.join("symlink.txt").read).to eq("file contents")
      expect(to_path.join("symlink.txt").symlink?).to be(true)
    end
  end

  it "copies a directory containing a symlink to a directory when overwrite is false" do
    Dir.mktmpdir do |dir|
      # Create source structure
      source_root = Pathname(dir).join("source").tap(&:mkpath)
      real_dir = source_root.join("real_dir").tap(&:mkpath)
      real_dir.join("file.txt").write("file contents")

      # Create a symlink to the real directory
      symlink_dir = source_root.join("symlink_dir")
      symlink_dir.make_symlink(real_dir)

      # Verify the symlink works
      expect(symlink_dir.symlink?).to be(true)
      expect(symlink_dir.directory?).to be(true)
      expect(symlink_dir.join("file.txt").read).to eq("file contents")

      # Create destination
      dest_path = Pathname(dir).join("destination").tap(&:mkpath)

      # Copy with overwrite: false
      LanguagePack::Helpers::FsExtra::Copy.new(
        from_path: source_root,
        to_path: dest_path,
        overwrite: false
      ).call

      # Verify the symlink was copied correctly
      copied_symlink = dest_path.join("symlink_dir")
      expect(copied_symlink.symlink?).to be(true)
      expect(copied_symlink.directory?).to be(true)
      expect(copied_symlink.join("file.txt").read).to eq("file contents")

      # Verify the real directory was also copied
      copied_real_dir = dest_path.join("real_dir")
      expect(copied_real_dir.directory?).to be(true)
      expect(copied_real_dir.join("file.txt").read).to eq("file contents")
    end
  end

  it "preserves file times and permissions when overwrite is true" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      from_path.join("file.txt").write("file contents")
      from_path.join("file.txt").utime(Time.now - 1000, Time.now - 1000)
      from_path.join("file.txt").chmod(0755)

      LanguagePack::Helpers::FsExtra::Copy.new(
        from_path: from_path,
        to_path: to_path,
        overwrite: true
      ).call

      expect(to_path.join("file.txt").mtime).to eq(from_path.join("file.txt").mtime)
      expect(to_path.join("file.txt").stat.mode).to eq(from_path.join("file.txt").stat.mode)
    end
  end

  it "preserves file times and permissions when overwrite is false" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      from_path.join("file.txt").write("file contents")
      from_path.join("file.txt").utime(Time.now - 1000, Time.now - 1000)
      from_path.join("file.txt").chmod(0755)

      LanguagePack::Helpers::FsExtra::Copy.new(
        from_path: from_path,
        to_path: to_path,
        overwrite: false
      ).call

      expect(to_path.join("file.txt").mtime).to eq(from_path.join("file.txt").mtime)
      expect(to_path.join("file.txt").stat.mode).to eq(from_path.join("file.txt").stat.mode)
    end
  end
end

describe LanguagePack::Helpers::FsExtra::RsyncDiff::RsyncDiffSummary do
  it "formats output when directories are different" do
    diff = LanguagePack::Helpers::FsExtra::RsyncDiff::RsyncDiffSummary.new(
      from_path: Pathname("/tmp/source"),
      to_path: Pathname("/tmp/destination"),
      output: ">f+++++++ file.txt\n",
      is_different: true
    )
    expect(diff.summary).to eq(<<~EOL)
      Directories `/tmp/source` and `/tmp/destination` differ (1/1 lines):

      >f+++++++ file.txt
    EOL
  end

  it "truncates output when over line limit" do
    diff = LanguagePack::Helpers::FsExtra::RsyncDiff::RsyncDiffSummary.new(
      from_path: Pathname("/tmp/source"),
      to_path: Pathname("/tmp/destination"),
      output: ">f+ file.txt\n" * 11,
      is_different: true
    )

    expect(diff.summary).to eq(<<~EOL)
      Directories `/tmp/source` and `/tmp/destination` differ (10/11 lines):

      >f+ file.txt
      >f+ file.txt
      >f+ file.txt
      >f+ file.txt
      >f+ file.txt
      >f+ file.txt
      >f+ file.txt
      >f+ file.txt
      >f+ file.txt
      >f+ file.txt
      And more ...
    EOL
  end

  it "formats output when directories are identical" do
    diff = LanguagePack::Helpers::FsExtra::RsyncDiff::RsyncDiffSummary.new(
      from_path: Pathname("/tmp/source"),
      to_path: Pathname("/tmp/destination"),
      output: "",
      is_different: false
    )
    expect(diff.summary.strip).to eq("Directories `/tmp/source` and `/tmp/destination` are identical")
  end
end

describe LanguagePack::Helpers::FsExtra::RsyncDiff do
  it "detects when directories are identical" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      from_path.join("file.txt").write("content")

      # Copy to ensure identical timestamps and avoid race conditions
      FileUtils.cp_r(
        from_path.children,
        to_path,
        preserve: true,
        dereference_root: false
      )

      io = StringIO.new
      diff = LanguagePack::Helpers::FsExtra::RsyncDiff.new(
        from_path: from_path,
        to_path: to_path,
        io: io
      ).call

      expect(io.string).to be_empty
      expect(diff.different?).to be(false), "Unexpected diff summary:\n\n#{diff.summary}"
    end
  end

  it "detects when directories are different (different file contents)" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      from_path.join("file.txt").write("content")

      # Copy to ensure identical timestamps and avoid race conditions
      FileUtils.cp_r(
        from_path.children,
        to_path,
        preserve: true,
        dereference_root: false
      )
      to_path.join("file.txt").write("different content")

      io = StringIO.new
      diff = LanguagePack::Helpers::FsExtra::RsyncDiff.new(
        from_path: from_path,
        to_path: to_path,
        io: io
      ).call

      expect(io.string).to be_empty
      expect(diff.different?).to be(true), "Unexpected diff summary:\n\n#{diff.summary}"
    end
  end

  it "detects when directories are different (added file in one directory)" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      from_path.join("file.txt").write("content")
      to_path.join("file.txt").write("different content")

      io = StringIO.new
      diff = LanguagePack::Helpers::FsExtra::RsyncDiff.new(
        from_path: from_path,
        to_path: to_path,
        io: io
      ).call

      expect(io.string).to be_empty
      expect(diff.different?).to be(true), "Unexpected diff summary:\n\n#{diff.summary}"
    end
  end

  it "detects differences when symlinks differ" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      # Create source with symlink
      from_path.join("realfile.txt").write("file contents")
      from_path.join("symlink.txt").make_symlink(from_path.join("realfile.txt"))

      # Create destination with different symlink target
      to_path.join("realfile.txt").write("file contents")
      to_path.join("symlink.txt").write("file contents")

      io = StringIO.new
      diff = LanguagePack::Helpers::FsExtra::RsyncDiff.new(
        from_path: from_path,
        to_path: to_path,
        io: io
      ).call

      expect(diff.different?).to be(true), "Unexpected diff summary:\n\n#{diff.summary}"
      expect(io.string).to be_empty
    end
  end

  it "detects when the target directory has extra files that the source directory does not" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      from_path.join("file.txt").write("content")
      to_path.join("file.txt").write("content")
      to_path.join("otherfile.txt").write("other content")

      io = StringIO.new
      diff = LanguagePack::Helpers::FsExtra::RsyncDiff.new(
        from_path: from_path,
        to_path: to_path,
        io: io
      ).call

      expect(diff.different?).to be(true), "Unexpected diff summary:\n\n#{diff.summary}"
      expect(io.string).to be_empty
    end
  end

  it "detects differences in file permissions" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      # Create identical files
      from_path.join("file.txt").write("content")
      to_path.join("file.txt").write("content")

      # Set different permissions
      from_path.join("file.txt").chmod(0755)
      to_path.join("file.txt").chmod(0644)

      io = StringIO.new
      diff = LanguagePack::Helpers::FsExtra::RsyncDiff.new(
        from_path: from_path,
        to_path: to_path,
        io: io
      ).call

      expect(diff.different?).to be(true), "Unexpected diff summary:\n\n#{diff.summary}"
      expect(io.string).to be_empty
    end
  end

  it "detects differences in file timestamps" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      # Create identical files
      from_path.join("file.txt").write("content")
      to_path.join("file.txt").write("content")

      # Set different timestamps
      from_path.join("file.txt").utime(Time.now - 1000, Time.now - 1000)
      to_path.join("file.txt").utime(Time.now - 500, Time.now - 500)

      io = StringIO.new
      diff = LanguagePack::Helpers::FsExtra::RsyncDiff.new(
        from_path: from_path,
        to_path: to_path,
        io: io
      ).call

      expect(diff.different?).to be(true), "Unexpected diff summary:\n\n#{diff.summary}"
      expect(io.string).to be_empty
    end
  end

  it "detects differences in directory structure" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      # Create nested structure in source
      from_path.join("subdir").tap(&:mkpath)
      from_path.join("subdir", "file.txt").write("content")

      # Create flat structure in destination
      to_path.join("file.txt").write("content")

      io = StringIO.new
      diff = LanguagePack::Helpers::FsExtra::RsyncDiff.new(
        from_path: from_path,
        to_path: to_path,
        io: io
      ).call

      expect(diff.different?).to be(true), "Unexpected diff summary:\n\n#{diff.summary}"
      expect(io.string).to be_empty
    end
  end

  it "detects differences in empty vs non-empty directories" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      # Source has a file, destination is empty
      from_path.join("file.txt").write("content")

      io = StringIO.new
      diff = LanguagePack::Helpers::FsExtra::RsyncDiff.new(
        from_path: from_path,
        to_path: to_path,
        io: io
      ).call

      expect(diff.different?).to be(true), "Unexpected diff summary:\n\n#{diff.summary}"
      expect(io.string).to be_empty
    end
  end

  it "detects differences when relative symlinks point outside directory with target existing" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      # Create a file outside the source directory
      outside_file = Pathname(dir).join("outside_file.txt")
      outside_file.write("outside content")

      # Create a relative symlink in source pointing outside
      from_path.join("symlink.txt").make_symlink("../outside_file.txt")

      # Create a regular file in destination (not a symlink)
      to_path.join("symlink.txt").make_symlink("different_content.txt")
      expect(to_path.join("symlink.txt").readlink.to_s).to eq("different_content.txt")
      expect(to_path.join("symlink.txt").symlink?).to be_truthy

      io = StringIO.new
      diff = LanguagePack::Helpers::FsExtra::RsyncDiff.new(
        from_path: from_path,
        to_path: to_path,
        io: io
      ).call

      expect(diff.different?).to be(true), "Unexpected diff summary:\n\n#{diff.summary}"
      expect(io.string).to be_empty
    end
  end

  it "detects if your version of rsync is recent enough (update rsync if this fails)" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      # Create a file outside the source directory
      outside_file = Pathname(dir).join("outside_file.txt")
      outside_file.write("outside content")

      # Create a relative symlink in source pointing outside
      from_path.join("symlink.txt").make_symlink("../outside_file.txt")

      output = `rsync --archive --verbose #{from_path}/ #{to_path}/`
      expect(output).to include("symlink.txt -> ../outside_file.txt")
      raise "Failed to run rsync: #{output}" unless $?.success?
      expect(to_path.join("symlink.txt").readlink.to_s).to eq("../outside_file.txt")
      expect(to_path.join("symlink.txt").symlink?).to be_truthy

      to_path.join("symlink.txt").tap(&:unlink).make_symlink("lol")

      output = `rsync --archive --stats --itemize-changes #{from_path}/ #{to_path}/`

      expect(to_path.join("symlink.txt").readlink.to_s).to eq("../outside_file.txt")
      expect(to_path.join("symlink.txt").symlink?).to be_truthy
      expect(output).to include("symlink.txt -> ../outside_file.txt")
    end
  end
end

describe LanguagePack::Helpers::FsExtra::CompareCopy do
  it "compares two directories" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      from_path.join("file.txt").write("content")
      to_path.join("file.txt").write("different content")

      compare = LanguagePack::Helpers::FsExtra::CompareCopy.new(
        from_path: from_path,
        to_path: to_path,
        reference_klass: LanguagePack::Helpers::FsExtra::Copy,
        test_klass: LanguagePack::Helpers::FsExtra::Copy,
        overwrite: true,
        name: "copy_compare",
      ).call

      expect(compare.different?).to be(false)
    end
  end

  it "reports a faulty copy operation produces a different result" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      from_path.join("file.txt").write("content")
      to_path.join("file.txt").write("different content")

      # test_klass is a mock that does nothing
      test_klass = Class.new do
        def initialize(**); end
        def call; end
      end

      compare = LanguagePack::Helpers::FsExtra::CompareCopy.new(
        from_path: from_path,
        to_path: to_path,
        reference_klass: LanguagePack::Helpers::FsExtra::Copy,
        test_klass: test_klass,
        overwrite: true,
        name: "copy_compare"
      ).call

      expect(compare.different?).to be(true)
    end
  end

    it "calls reference_klass.new 3 times and test_klass.new 1 time" do
    Dir.mktmpdir do |dir|
      from_path = Pathname(dir).join("source").tap(&:mkpath)
      to_path = Pathname(dir).join("destination").tap(&:mkpath)

      reference = spy("reference")
      test = spy("test")

      allow(reference).to receive(:new).and_return(double("reference_instance", call: true))
      allow(test).to receive(:new).and_return(double("test_instance", call: true))

      LanguagePack::Helpers::FsExtra::CompareCopy.new(
        from_path: from_path,
        to_path: to_path,
        reference_klass: reference,
        test_klass: test,
        overwrite: true,
        name: "copy_compare"
      ).call

      # Verify the call counts
      expect(reference).to have_received(:new).exactly(3).times
      expect(test).to have_received(:new).exactly(1).time
    end
  end
end
