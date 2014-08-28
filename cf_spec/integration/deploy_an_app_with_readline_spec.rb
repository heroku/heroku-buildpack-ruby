$: << 'cf_spec'
require 'cf_spec_helper'

describe 'CF Ruby Buildpack' do
  subject(:app) { Machete.deploy_app(app_name) }
  let(:app_name) { 'app_with_readline' }
  let(:browser) { Machete::Browser.new(app) }

  context 'in an online environment', if: Machete::BuildpackMode.online? do
    specify do
      expect(app).to be_running
      expect(app).not_to have_logged 'cannot open shared object file'

      browser.visit_path('/')
      expect(browser).to have_body('Hello world!')
    end
  end
end
