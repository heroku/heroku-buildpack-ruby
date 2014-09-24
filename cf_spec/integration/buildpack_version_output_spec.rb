$: << 'cf_spec'
require 'cf_spec_helper'

describe 'Version output' do
  subject(:app) { Machete.deploy_app(app_name) }
  let(:app_name) { 'sinatra_web_app' }

  context 'in an online environment', if: Machete::BuildpackMode.online? do
    specify do
      expect(app).to have_logged '-------> Buildpack version 1.1.1'
    end
  end
end
