$: << 'cf_spec'
require "cf_spec_helper"

describe 'deploying a rails 4 application', :ruby_buildpack do
  it 'make the homepage available' do
    Machete.deploy_app("rails4_web_app", with_pg: true) do |app|
      expect(app).to be_staged
      expect(app.homepage_html).to include('The Kessel Run')
    end
  end

  it "deploys apps without vendored dependencies", if: Machete::BuildpackMode.online? do
    app_name = "rails4_web_app_without_vendored_dependencies"

    expect(Dir.exists?("cf_spec/fixtures/#{app_name}/vendor")).to eql(false)

    Machete.deploy_app(app_name, with_pg: true) do |app|
      expect(app).to be_staged
      expect(app.homepage_html).to include('The Kessel Run')
    end
  end
end
