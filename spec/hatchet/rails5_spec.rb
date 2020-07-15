require_relative '../spec_helper'

describe "Rails 5" do
  it "works" do
    Hatchet::Runner.new("rails5").deploy do |app, heroku|
      # Test BUNDLE_DISABLE_VERSION_CHECK works
      expect(app.output).not_to include("The latest bundler is")

      # Test worker task only appears if the app has that rake task
      worker_task = worker_task_for_app(app)
      expect(worker_task).to be_nil

      run!(%Q{echo "task 'jobs:work' do ; end" >> Rakefile})
      app.commit!

      app.deploy do
        worker_task = worker_task_for_app(app)
        expect(worker_task["command"]).to eq("bundle exec rake jobs:work")
      end
    end
  end

  def worker_task_for_app(app)
    app
     .api_rate_limit.call
     .formation
     .list(app.name)
     .detect { |h| h["type"] == "worker" }
  end

  describe "active storage" do
    it "non-local storage warnings" do
      Hatchet::Runner.new("active_storage_non_local").deploy do |app, heroku|
        expect(app.output).to     match('binary dependencies required')
        expect(app.output).to_not match('config.active_storage.service')
        expect(app.output).to_not match(/\$ rails runner/)
      end
    end

    it "local storage warnings" do
      app = Hatchet::Runner.new(
        "active_storage_local",
        buildpacks: [
          "https://github.com/heroku/heroku-buildpack-activestorage-preview",
          :default
        ]
      )
      app.setup!
      app.set_config('HEROKU_DEBUG_RAILS_RUNNER' => 'true')
      app.deploy do |app, heroku|
        expect(app.output).to_not match('binary dependencies required')
        expect(app.output).to     match('config.active_storage.service')
        expect(app.output).to     match('config.assets.compile = true')
        expect(app.output).to     match(/\$ rails runner/)
      end
    end
  end

  it "blocks bads sprockets config with bad version" do
    Hatchet::Runner.new("sprockets_asset_compile_true", allow_failure: true).deploy do |app, heroku|
      expect(app.output).to match('A security vulnerability has been detected')
      expect(app.output).to match('version "3.7.2"')
    end
  end
end

describe "Rails 5.1 with webpacker" do
  it "calls bin/yarn no matter what is on the path" do
    Hatchet::Runner.new("rails51_webpacker").tap do |app|
      # We put our version of yarn first on the path ahead of bin/yarn
      # however webpacker explicitly calls bin/yarn instead of calling
      # `yarn install`
      app.before_deploy do
        File.open("bin/yarn", "w") do |f|
          f.write <<~EOM
          #! /usr/bin/env bash

          echo "Called bin/yarn binstub"
          `yarn install`
          EOM
        end
        run("chmod +x bin/yarn")
      end

      app.deploy do
        expect(app.output).to include("Called bin/yarn binstub")

        expect(app.output).to match("rake assets:precompile")
        expect(app.output).to match("rake assets:clean")
      end
    end
  end
end
