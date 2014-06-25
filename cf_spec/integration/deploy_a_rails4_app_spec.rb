$: << 'cf_spec'
require 'cf_spec_helper'

describe 'Rails 4 App' do
  subject(:app) { Machete.deploy_app(app_name, with_pg: true) }

  context 'in an offline environment', if: Machete::BuildpackMode.offline? do
    let(:app_name) { 'rails4_web_app' }

    specify do
      expect(app).to be_running
      expect(app.homepage_body).to include 'The Kessel Run'
      expect(app).not_to have_internet_traffic
    end

  end

  context 'in an online environment', if: Machete::BuildpackMode.online? do
    context 'app has dependencies' do
      let(:app_name) { 'rails4_web_app' }

      specify do
        expect(app).to be_running
        expect(app.homepage_body).to include 'The Kessel Run'
      end
    end

    context 'app has no dependencies' do
      let(:app_name) { 'rails4_web_app_without_vendored_dependencies' }

      specify do
        expect(Dir.exists?("cf_spec/fixtures/#{app_name}/vendor")).to eql(false)
        expect(app).to be_running
        expect(app.homepage_body).to include 'The Kessel Run'
      end
    end
  end
end
