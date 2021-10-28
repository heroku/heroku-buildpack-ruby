require_relative '../spec_helper'

class CnbRun
  attr_accessor :image_name, :output, :repo_path, :buildpack_path, :builder

  def initialize(repo_path, builder: "heroku/buildpacks:18", buildpack_paths: )
    @repo_path = repo_path
    @image_name = "heroku-buildpack-ruby-tests:#{SecureRandom.hex}"
    @builder = builder
    @buildpack_paths = Array.new(buildpack_paths)
    @build_output = ""
  end

  def call
    command = String.new("pack build #{image_name} --path #{repo_path} --builder heroku/buildpacks:18")
    @buildpack_paths.each do |path|
      command << " --buildpack #{path}"
    end

    @output = run_local!(command)
    yield self
  ensure
    teardown
  end

  def teardown
    return unless image_name
    repo_name, tag_name = image_name.split(":")

    docker_list = `docker images --no-trunc | grep #{repo_name} | grep #{tag_name}`.strip
    run_local!("docker rmi #{image_name} --force") if !docker_list.empty?
    @image_name = nil
  end

  def run(cmd)
    `docker run #{image_name} '#{cmd}'`.strip
  end

  def run!(cmd)
    out = run(cmd)
    raise "Command #{cmd.inspect} failed. Output: #{out}" unless $?.success?
    out
  end

  private def run_local!(cmd)
    out = `#{cmd}`
    raise "Command #{cmd.inspect} failed. Output: #{out}" unless $?.success?
    out
  end
end

describe "cnb" do
  it "locally runs default_ruby app" do
    CnbRun.new(hatchet_path("rack/default_ruby"), buildpack_paths: [buildpack_path]).call do |app|
      expect(app.output).to match("Compiling Ruby/Rack")

      run_out = app.run!("ruby -v")
      expect(run_out).to match(LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER)
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
          id = "heroku-18"

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

      CnbRun.new(hatchet_path("rack/default_ruby"), buildpack_paths: [buildpack_path, second_buildpack_dir]).call do |app|
        expect(app.output).to match("Compiling Ruby/Rack")

        expect(app.output).to match("com.examples.buildpacks.test_ruby_export")
        expect(app.output).to match("Which gem: /workspace/bin/gem")
      end
    end
  end

  it "locally runs rails getting started" do
    CnbRun.new(hatchet_path("heroku/ruby-getting-started"), buildpack_paths: [buildpack_path]).call do |app|
      expect(app.output).to match("Compiling Ruby/Rails")

      run_out = app.run!("ruby -v")
      expect(run_out).to match("2.6.6")
    end
  end
end

