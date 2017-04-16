require "spec_helper"

describe LanguagePack::Ruby do
  describe "#install_binary" do
    context "installing yarn" do
      before do
        @old_path = ENV['PATH']
        @old_stack = ENV['STACK']
        ENV['STACK'] = 'cedar-14'
      end

      after do
        ENV['PATH'] = @old_path
        ENV['STACK'] = @old_stack
      end

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
  end
end
