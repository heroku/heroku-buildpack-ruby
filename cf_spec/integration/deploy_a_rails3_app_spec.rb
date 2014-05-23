$: << 'cf_spec'
require "cf_spec_helper"

describe 'deploying a rails 3 application', :ruby_buildpack do
  it 'make the homepage available' do
    Machete.deploy_app("rails3_mri_193", :ruby, with_pg: true) do |app|
      expect(app).to be_staged
      expect(app.homepage_html).to include('hello')
    end
  end
end
