require "spec_helper"

describe LanguagePack::Installers::HerokuRubyInstaller do
  let(:installer)    { LanguagePack::Installers::HerokuRubyInstaller.new("cedar-14") }
  let(:ruby_version) { LanguagePack::RubyVersion.new("ruby-2.3.3") }

  describe "#fetch_unpack" do

    it "should fetch and unpack mri" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          installer.fetch_unpack(ruby_version, dir)

          expect(File).to exist("bin/ruby")
        end
      end
    end

    context "build rubies" do
      let(:ruby_version) { LanguagePack::RubyVersion.new("ruby-1.9.2") }

      it "should fetch and unpack the build ruby" do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            installer.fetch_unpack(ruby_version, dir, true)

            expect(File.read("lib/ruby/1.9.1/x86_64-linux/rbconfig.rb")).to include(%q{CONFIG["prefix"] = (TOPDIR || DESTDIR + "/tmp/ruby-1.9.2")})
            expect(File).to exist("bin/ruby")
          end
        end
      end

    end
  end

  describe "#install" do

    it "should install ruby and setup binstubs" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          installer.install(ruby_version, "#{dir}/vendor/ruby")

          expect(File.symlink?("#{dir}/bin/ruby")).to be true
          expect(File.symlink?("#{dir}/bin/ruby.exe")).to be true
          expect(File).to exist("#{dir}/vendor/ruby/bin/ruby")
        end
      end
    end

  end

  describe "#setup_binstubs" do
    it "warns about malformed shebangs" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          Dir.mkdir("bin")
          File.open("bin/rake", 'w') { |f| f.write("#!/usr/bin/env ruby") }
          File.open("bin/rails", 'w') { |f| f.write("#!/usr/bin/env ruby.exe") }
          File.open("bin/bundle", 'w') { |f| f.write("#!/usr/bin/env ruby1.7") }

          output = capture(:stdout) { installer.setup_binstubs("#{dir}/vendor/ruby") }

          expect(output).to include(<<-WARNING)
###### WARNING:
       Binstub bin/bundle contains shebang #!/usr/bin/env ruby1.7. This may cause issues if the program specified is unavailable.
          WARNING
        end
      end
    end

    def capture(stream)
      stream = stream.to_s
      captured_stream = Tempfile.new(stream)
      stream_io = eval("$#{stream}")
      origin_stream = stream_io.dup
      stream_io.reopen(captured_stream)

      yield

      stream_io.rewind
      return captured_stream.read
    ensure
      captured_stream.close
      captured_stream.unlink
      stream_io.reopen(origin_stream)
    end
  end
end
