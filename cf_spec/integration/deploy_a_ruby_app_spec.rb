$: << 'cf_spec'
require 'cf_spec_helper'

describe 'CF Ruby Buildpack' do
  subject(:app) { Machete.deploy_app(app_name, env: env) }
  let(:browser) { Machete::Browser.new(app) }
  let(:env) do
    {BUNDLE_GEMFILE: 'different.Gemfile'}
  end

  context 'deploying an app with more than one Gemfile', if: Machete::BuildpackMode.online? do
    let(:app_name) { 'app_with_multiple_gemfiles' }

    specify do
      expect(app).to be_running
      expect(app).not_to have_logged 'cannot load such file -- sinatra'

      browser.visit_path('/')
      expect(browser).to have_body('Hello world!')
    end
  end
end
