require_relative '../spec_helper'

describe "cnb" do
  it "locally runs default_ruby app" do
    Cutlass::App.new("default_ruby").transaction do |app|
      app.pack_build

      expect(app.stdout).to include("Installing rake")

      app.run_multi("ruby -v") do |out|
        expect(out.stdout).to match(LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER)
      end

      app.run_multi("bundle list") do |out|
        expect(out.stdout).to match("rack")
      end

      app.run_multi("gem list") do |out|
        expect(out.stdout).to match("rack")
      end

      app.run_multi(%Q{ruby -e "require 'rack'; puts 'done'"}) do |out|
        expect(out.stdout).to match("done")
      end

      # Test cache
      app.pack_build

      expect(app.stdout).to include("Using rake")
    end
  end

  it "uses multiple buildpacks" do
    Dir.mktmpdir do |second_buildpack_dir|
      FileUtils.mkdir_p("#{second_buildpack_dir}/bin")

      File.open("#{second_buildpack_dir}/buildpack.toml", "w") do |f|
        f.write <<~EOM
          # Buildpack API version
          api = "0.2"

          # Buildpack ID and metadata
          [buildpack]
          id = "com.examples.buildpacks.test_ruby_export"
          version = "0.0.1"
          name = "Test Ruby Export Buildpack"

          # Stacks that the buildpack will work with
          [[stacks]]
          id = "heroku-20"

          [[stacks]]
          id = "org.cloudfoundry.stacks.cflinuxfs3"
        EOM
      end
      File.open("#{second_buildpack_dir}/bin/detect", "w") do |f|
        f.write <<~EOM
          #! /usr/bin/env bash

          exit 0
        EOM
      end

      File.open("#{second_buildpack_dir}/bin/build", "w") do |f|
        f.write <<~EOM
          #! /usr/bin/env bash

          echo "Which gem: $(which gem)"
          exit 0
        EOM
      end
      FileUtils.chmod("+x", "#{second_buildpack_dir}/bin/detect")
      FileUtils.chmod("+x", "#{second_buildpack_dir}/bin/build")

      Cutlass::App.new("default_ruby", buildpacks: [:default, second_buildpack_dir]).transaction do |app|
        app.pack_build

        expect(app.stdout).to match("Compiling Ruby/Rack")

        expect(app.stdout).to match("com.examples.buildpacks.test_ruby_export")
        expect(app.stdout).to match("Which gem: /workspace/bin/gem")
      end
    end
  end

  it "locally runs rails getting started" do
    Cutlass::App.new("ruby-getting-started").transaction do |app|
      app.pack_build
      expect(app.stdout).to match("Compiling Ruby/Rails")

      expect(app.run("ruby -v").stdout).to match("3.1.2")
    end
  end
end

