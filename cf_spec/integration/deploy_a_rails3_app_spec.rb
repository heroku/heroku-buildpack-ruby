$: << 'cf_spec'
require "cf_spec_helper"

describe 'deploying a rails 3 application', :ruby_buildpack do
  it 'succeeds' do
    Machete.deploy_app("rails3_mri_193", with_pg: true) do |app|
      expect(app).to be_staged
      expect(app.homepage_html).to include('hello')
      expect(app).to have_file('app/vendor/plugins/rails3_serve_static_assets/init.rb')
    end
  end
end
