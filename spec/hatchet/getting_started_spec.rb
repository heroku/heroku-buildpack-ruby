require_relative '../spec_helper'

describe "Heroku ruby getting started" do
  it "works on Heroku-24" do
    Hatchet::Runner.new("ruby-getting-started", stack: "heroku-24").deploy do |app|
      expect(app.output).to_not include("Purging Cache")
      # Assert sprockets build cache not present on runtime
      expect(app.run("ls tmp/cache/assets")).to_not match("sprockets")

      # Re-deploy with cache
      run!("git commit --allow-empty -m empty")
      app.push!

      # Assert no warnings from `cp`
      # https://github.com/heroku/heroku-buildpack-ruby/pull/1586/files#r2064284286
      expect(app.output).to_not include("cp --help")
      expect(app.run("which ruby").strip).to eq("/app/bin/ruby")
    end
  end

  # Temp test to make sure that the experiment is working in prod
  # Can be removed after FsExtra::Copy is the only copy implementation
  it "works with the copy experiment enabled" do
    buildpacks = [
      :default,
      "https://github.com/heroku/heroku-buildpack-inline.git",
    ]
    app = Hatchet::Runner.new(
      "ruby-getting-started",
      stack: "heroku-24",
      buildpacks: buildpacks,
      config: { "HEROKU_FORCE_COPY_EXPERIMENT" => "1" }
    )
    app.before_deploy do
      # Inline buildpack to ensure build_report file is emitted on compile
      bin = Pathname("bin").tap(&:mkpath)
      detect = bin.join("detect")
      compile = bin.join("compile")
      release = bin.join("release")

      [detect, compile, release].each do |path|
        FileUtils.touch(path)
        FileUtils.chmod("+x", path)
        path.write(<<~EOF)
          #!/usr/bin/env bash
          exit 0
        EOF
      end

      compile.write(<<~EOF)
        #!/usr/bin/env bash
        REPORT_FILE="${CACHE_DIR}/.heroku/ruby/build_report.yml"
        echo "## PRINTING REPORT FILE ##"
        #{Pathname(__dir__).join("..").join("..").join("bin").join("report").read}
        echo "## REPORT FILE DONE ##"
      EOF
    end

    app.deploy do |app|
      expect(app.output).to_not include("Purging Cache")
      # Assert sprockets build cache not present on runtime
      expect(app.run("ls tmp/cache/assets")).to_not match("sprockets")

      fetching_rake = "Fetching rake"
      expect(app.output).to match(fetching_rake)

      # Re-deploy with cache
      run!("git commit --allow-empty -m empty")
      app.push!

      expect(app.output).to_not match(fetching_rake)

      begin
        report_match = app.output.match(/## PRINTING REPORT FILE ##(?<yaml>.*)## REPORT FILE DONE/m) # https://rubular.com/r/FfaV5AEstigaMO
        expect(report_match).to be_truthy
        yaml = report_match[:yaml].gsub(/remote: /, "")
        report = YAML.load(yaml)
        expect(report.fetch("fs_extra_diff_different")).to eq(false)
      rescue Exception => e
        puts app.output
        puts yaml if yaml
        puts report.inspect if report
        raise e
      end
    end
  end

  it "works on Heroku-22" do
    Hatchet::Runner.new("ruby-getting-started", stack: "heroku-22").deploy do |app|
      # Re-deploy with cache
      run!("git commit --allow-empty -m empty")
      app.push!

      # Assert no warnings from `cp`
      # https://github.com/heroku/heroku-buildpack-ruby/pull/1586/files#r2064284286
      expect(app.output).to_not include("cp --help")
      expect(app.run("which ruby").strip).to eq("/app/bin/ruby")
    end
  end
end
