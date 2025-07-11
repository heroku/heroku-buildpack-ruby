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
    Hatchet::Runner.new("ruby-getting-started", stack: "heroku-24", config: { "HEROKU_FORCE_COPY_EXPERIMENT" => "1" }).deploy do |app|
      expect(app.output).to_not include("Purging Cache")
      # Assert sprockets build cache not present on runtime
      expect(app.run("ls tmp/cache/assets")).to_not match("sprockets")


      fetching_rake = "Fetching rake"
      expect(test_run.output).to match(fetching_rake)


      # Re-deploy with cache
      run!("git commit --allow-empty -m empty")
      app.push!

      expect(test_run.output).to_not match(fetching_rake)

      # Assert no warnings from `cp`
      # https://github.com/heroku/heroku-buildpack-ruby/pull/1586/files#r2064284286
      expect(app.output).to_not include("cp --help")
      expect(app.run("which ruby").strip).to eq("/app/bin/ruby")

      begin
        report = YAML.load(yaml)
        yaml = app.run("cat .heroku/ruby/build_report.yml")
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
