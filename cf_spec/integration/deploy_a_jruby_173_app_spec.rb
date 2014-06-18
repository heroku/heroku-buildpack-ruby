$: << 'cf_spec'
require 'cf_spec_helper'

describe 'JRuby 1.7.3 App' do
  subject(:app) { Machete.deploy_app(app_name) }
  let(:app_name) { 'sinatra_jruby_web_app' }

  context 'in an offline environment', if: Machete::BuildpackMode.offline? do
    specify do
      expect(app).to be_staged
      expect(app.output).to match('Installing JVM')
      expect(app.output).to match('ruby-1.8.7-jruby-1.7.8')
      expect(app.output).not_to include('OpenJDK 64-Bit Server VM warning')
      expect(app).to have_no_internet_traffic
    end
  end

  context 'in an online environment', if: Machete::BuildpackMode.online? do
    specify do
      expect(app).to be_staged
      expect(app.output).to match('Installing JVM')
      expect(app.output).to match('ruby-1.8.7-jruby-1.7.8')
      expect(app.output).not_to include('OpenJDK 64-Bit Server VM warning')
    end
  end
end
