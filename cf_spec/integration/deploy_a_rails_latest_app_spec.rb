$: << 'cf_spec'
require 'cf_spec_helper'

describe 'Rails latest App' do
  subject(:app) { Machete.deploy_app(app_name, with_pg: true) }
  let(:app_name) { 'rails_latest_web_app' }

  context 'in an offline environment', if: Machete::BuildpackMode.offline? do
    specify do
      expect(app).to be_staged
      expect(app.homepage_html).to include('Listing people')
      expect(app).to have_no_internet_traffic
    end
  end

  context 'in an online environment', if: Machete::BuildpackMode.online? do
    specify do
      expect(app).to be_staged
      expect(app.homepage_html).to include('Listing people')
    end
  end
end