require_relative '../spec_helper'

describe "Rails 6" do
  it "should detect successfully" do
    Hatchet::App.new('rails6-basic').in_directory_fork do
      expect(LanguagePack::Rails5.use?).to eq(false)
      expect(LanguagePack::Rails6.use?).to eq(true)
    end
  end

  it "deploys and serves web requests via puma" do
    before_deploy = Proc.new do
      run! "echo 'web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}' > Procfile"
    end

    Hatchet::Runner.new('rails6-basic', before_deploy: before_deploy).deploy do |app|
      expect(app.output).to match("Fetching railties 6")
      expect(web_boot_status(app)).to_not eq("crashed")
    end
  end
end
