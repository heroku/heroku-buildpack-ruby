require "spec_helper"
require "rake/tarballer"

def real_entries(dir)
  Dir.entries(dir) - [".", ".."]
end

describe "tarballer" do
  it "blerg" do
    Dir.mktmpdir do |dir|
      dir = Pathname.new(dir)
      run!("echo 'foo' >> #{dir}/foo.txt")
      run!("mkdir -p #{dir}/vendor/ruby")

      tarballer = Tarballer.new(name: 'heroku-buildpack-ruby', directory: dir, io: StringIO.new)
      tarballer.call(stacks: ["heroku-18"])

      # Test tar generated
      tgz_name = "heroku-buildpack-ruby-#{LanguagePack::Base::BUILDPACK_VERSION}.tgz"
      buildpacks_dir = real_entries("#{dir}/buildpacks")
      expect(buildpacks_dir).to include(tgz_name)

      # Test tar contents
      tgz_file = dir.join("buildpacks", tgz_name)
      tar_contents = run!("tar -tvf #{tgz_file}").strip
      expect(tar_contents).to include("vendor/ruby/heroku-18/bin/gem")
      expect(tar_contents).to include("foo.txt")
    end
  end
end
