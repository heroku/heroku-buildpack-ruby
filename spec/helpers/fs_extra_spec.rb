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

