require "spec_helper"

describe LanguagePack::Helpers::Nodebin do
  describe ".yarn" do
    it "downloads Yarn from the npm registry (not the heroku-nodebin S3 bucket)" do
      url = LanguagePack::Helpers::Nodebin.yarn["url"]

      expect(url).to include("registry.npmjs.org")
      expect(url).to_not include("heroku-nodebin")
      expect(url).to eq("https://registry.npmjs.org/yarn/-/yarn-#{LanguagePack::Helpers::Nodebin::YARN_VERSION}.tgz")
    end
  end
end
