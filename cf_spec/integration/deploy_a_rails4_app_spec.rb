$: << 'cf_spec'
require "cf_spec_helper"

describe 'deploying a rails 4 application', :ruby_buildpack do
  it 'make the homepage available' do
    Machete.deploy_app("rails4_web_app", :ruby, with_pg: true) do |app|
      expect(app).to be_staged
      expect(app.homepage_html).to include('The Kessel Run')
    end
  end
end
