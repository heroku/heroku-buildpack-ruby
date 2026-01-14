require_relative "../spec_helper"

describe "Rails 6" do
  it "should detect successfully" do
    Hatchet::App.new("rails61").in_directory_fork do
      bundler = LanguagePack::Helpers::BundlerWrapper.new(
        bundler_path: Dir.mktmpdir,
        bundler_version: LanguagePack::Helpers::BundlerWrapper::DEFAULT_VERSION
      )
      expect(LanguagePack::Rails5.use?(bundler: bundler)).to eq(false)
      expect(LanguagePack::Rails6.use?(bundler: bundler)).to eq(true)
    end
  end

  it "deploys and serves web requests via puma" do
    before_deploy = proc do
      run! "echo 'web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}' > Procfile"

      # Test Clean task does not get called if it does not exist
      # This file will only have the `assets:precompile` task in it, but not `assets:clean`
      run! %(echo 'task "assets:precompile" do ; end' > Rakefile)
    end

    Hatchet::Runner.new("rails61", before_deploy: before_deploy, config: rails_lts_config, stack: rails_lts_stack).deploy do |app|
      expect(app.output).to match("Fetching railties 6")

      expect(app.output).to match("rake assets:precompile")
      expect(app.output).to_not match("rake assets:clean")

      expect(web_boot_status(app)).to_not eq("crashed")
    end
  end
end
