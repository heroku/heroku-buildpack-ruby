$: << 'cf_spec'
require "cf_spec_helper"

describe 'deploying a jruby 1.7.3 application', :ruby_buildpack do
  it "deploys a jruby 1.7.3 (legacy jdk) properly" do
    Machete.deploy_app("sinatra_jruby_web_app", :ruby) do |app|
      expect(app).to be_staged
      expect(app.output).to match("Installing JVM")
      expect(app.output).to match("ruby-1.8.7-jruby-1.7.8")
      expect(app.output).not_to include("OpenJDK 64-Bit Server VM warning")
    end
  end
end
