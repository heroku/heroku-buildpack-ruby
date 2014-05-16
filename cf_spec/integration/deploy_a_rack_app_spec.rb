$: << 'cf_spec'
require "cf_spec_helper"

describe 'deploying a rack application', :ruby_buildpack do
  it 'make the homepage available' do
    Machete.deploy_app("sinatra_web_app", :ruby) do |app|
      expect(app).to be_staged
      expect(app.homepage_html).to include('Hello world!')
    end
  end
end
