$: << 'cf_spec'
require 'cf_spec_helper'

describe 'Rails 3 App' do
  subject(:app) { Machete.deploy_app(app_name, with_pg: true) }
  let(:app_name) { 'rails3_mri_193' }

  context 'in an offline environment', if: Machete::BuildpackMode.offline? do
    specify do
      expect(app).to be_staged
      expect(app.homepage_html).to include('hello')
      expect(app).to have_file('app/vendor/plugins/rails3_serve_static_assets/init.rb')
      expect(app).to have_no_internet_traffic
    end
  end

  context 'in an online environment', if: Machete::BuildpackMode.online? do
    specify do
      expect(app).to be_staged
      expect(app.homepage_html).to include('hello')
      expect(app).to have_file('app/vendor/plugins/rails3_serve_static_assets/init.rb')
    end
  end
end
