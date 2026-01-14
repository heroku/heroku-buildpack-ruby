require_relative "../spec_helper"

describe "Rails 7" do
  it "should detect successfully" do
    Hatchet::App.new("rails-jsbundling").in_directory_fork do
      bundler = LanguagePack::Helpers::BundlerWrapper.new(
        bundler_path: Dir.mktmpdir,
        bundler_version: LanguagePack::Helpers::BundlerWrapper::DEFAULT_VERSION
      )
      expect(LanguagePack::Rails6.use?(bundler: bundler)).to eq(false)
      expect(LanguagePack::Rails7.use?(bundler: bundler)).to eq(true)
    end
  end

  it "works with jsbundling" do
    Hatchet::Runner.new("rails-jsbundling").tap do |app|
      app.deploy do
        expect(app.output).to include("yarn install")
        expect(app.output).to include("Asset precompilation completed")
      end
    end
  end

  it "Works on Heroku CI" do
    Hatchet::Runner.new("rails-jsbundling").run_ci do |test_run|
      expect(test_run.output).to match("db:schema:load")
      expect(test_run.output).to match("db:migrate")
    end
  end
end
