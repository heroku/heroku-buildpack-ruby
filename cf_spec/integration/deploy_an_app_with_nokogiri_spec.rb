$: << 'cf_spec'
require 'cf_spec_helper'

describe 'Installing Nokogiri' do
  subject(:app) { Machete.deploy_app(app_name) }
  let(:app_name) { 'mri_187_nokogiri' }

  context 'in an offline environment', if: Machete::BuildpackMode.offline? do
    specify do
      expect(app).to be_staged
      expect(app.output).to match('Installing nokogiri')
      expect(app).to have_no_internet_traffic
    end
  end

  context 'in an online environment', if: Machete::BuildpackMode.online? do
    specify do
      expect(app).to be_staged
      expect(app.output).to match('Installing nokogiri')
    end
  end
end
