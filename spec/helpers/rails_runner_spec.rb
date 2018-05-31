require 'spec_helper'

describe "Rails Runner" do
  it "config objects build propperly formatted commands" do
    rails_runner  = LanguagePack::Helpers::RailsRunner.new
    local_storage = rails_runner.detect("active_storage.service")

    expected = 'rails runner "begin; puts %Q{heroku.detecting.config.for.active_storage.service=#{Rails.application.config.try(:active_storage).try(:service)}}; rescue => e; end;"'
    expect(rails_runner.command).to eq(expected)

    rails_runner.detect("assets.compile")

    expected = 'rails runner "begin; puts %Q{heroku.detecting.config.for.active_storage.service=#{Rails.application.config.try(:active_storage).try(:service)}}; rescue => e; end; begin; puts %Q{heroku.detecting.config.for.assets.compile=#{Rails.application.config.try(:assets).try(:compile)}}; rescue => e; end;"'
    expect(rails_runner.command).to eq(expected)
  end

  it "calls run through child object" do
    rails_runner  = LanguagePack::Helpers::RailsRunner.new
    def rails_runner.call; @called ||= 0 ; @called += 1; end
    def rails_runner.called; @called; end

    local_storage = rails_runner.detect("active_storage.service")
    local_storage.success?
    expect(rails_runner.called).to eq(1)

    local_storage.success?
    local_storage.did_match?("foo")
    expect(rails_runner.called).to eq(1)
  end
end

