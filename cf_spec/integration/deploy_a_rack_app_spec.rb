$: << 'cf_spec'
require 'cf_spec_helper'

describe 'Rack App' do
  subject(:app) { Machete.deploy_app(app_name) }
  let(:app_name) { 'sinatra_web_app' }

  context 'in an offline environment', if: Machete::BuildpackMode.offline? do
    specify do
      expect(app).to be_running
      expect(app.homepage_body).to include('Hello world!')
      expect(app.host).not_to have_internet_traffic
    end
  end

  context 'in an online environment', if: Machete::BuildpackMode.online? do
    specify do
      expect(app).to be_running
      expect(app.homepage_body).to include('Hello world!')
    end
  end
end
