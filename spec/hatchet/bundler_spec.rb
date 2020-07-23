require 'spec_helper'

describe "Bundler" do
  it "deploys with version 2.x" do
    before_deploy = Proc.new do
      run!(%Q{echo "ruby '2.5.7'" >> Gemfile})
      run!(%Q{printf "\nBUNDLED WITH\n   2.0.1\n" >> Gemfile.lock})
    end

    Hatchet::Runner.new("default_ruby", before_deploy: before_deploy).deploy do |app|
      expect(app.output).to match("Installing dependencies using bundler 2.")

      # Double deploy problem with Ruby 2.5.5
      run!(%Q{git commit --allow-empty -m 'Deploying again'})
      app.push!
    end
  end
end
