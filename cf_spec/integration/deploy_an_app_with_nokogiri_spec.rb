$: << 'cf_spec'
require "cf_spec_helper"

describe "Bugs", :ruby_buildpack do
  context "MRI 1.8.7" do
    it "should install nokogiri" do
      Machete.deploy_app("mri_187_nokogiri", :ruby) do |app|
        expect(app).to be_staged
        expect(app.output).to match("Installing nokogiri")
      end
    end
  end
end
