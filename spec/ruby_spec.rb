require "spec_helper"

describe LanguagePack::Ruby do
  describe "#install_binary" do
    before do
      @old_path = ENV['PATH']
      @old_stack = ENV['STACK']
      ENV['STACK'] = 'cedar-14'
    end

    after do
      ENV['PATH'] = @old_path
      ENV['STACK'] = @old_stack
    end

    context "installing yarn" do
      it "sets up PATH" do
        Dir.mktmpdir do |build_path|
          Dir.mktmpdir do |cache_path|
            Dir.chdir(build_path) do
              ruby = LanguagePack::Ruby.new(build_path, cache_path)
              ruby.send(:install_binary, "yarn-0.22.0")
              expect(ENV["PATH"]).to include("vendor/yarn")
            end
          end
        end
      end

    end
  describe "#warn_bad_binstubs" do
    it "warns about malformed shebangs" do
      Dir.mktmpdir do |build_path|
        Dir.mktmpdir do |cache_path|
          Dir.chdir(build_path) do
            Dir.mkdir("bin")
            File.open("bin/rake", 'w') { |f| f.write("#!/usr/bin/env ruby") }
            File.open("bin/rails", 'w') { |f| f.write("#!/usr/bin/env ruby.exe") }
            File.open("bin/bundle", 'w') { |f| f.write("#!/usr/bin/env ruby1.7") }

            ruby = LanguagePack::Ruby.new(build_path, cache_path)
            output = capture(:stdout) { ruby.send(:warn_bad_binstubs) }

            expect(output).to include(<<-WARNING)
###### WARNING:
       Binstub bin/bundle contains shebang #!/usr/bin/env ruby1.7. This may cause issues if the program specified is unavailable.
            WARNING
          end
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

end
