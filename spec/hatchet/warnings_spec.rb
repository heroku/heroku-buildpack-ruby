require_relative "../spec_helper"

describe "Best practice warnings" do
  it "should warn when using x_sendfile_header" do
    app = Hatchet::Runner.new("rails5")
    app.in_directory do
      add_composer_json!
      set_x_sendfile_config!

      app.setup!
      app.push_with_retry!
    end

    assert(app.output).to match(%r{you do not have `apache` installed on this app})
  ensure
    app.teardown! if app
  end

  it "should not warn when binary is present" do
    buildpacks = [
      "heroku/php", # used for adding apache
      Hatchet::App.default_buildpack
    ]
    app = Hatchet::Runner.new("rails5", buildpacks: buildpacks)
    app.in_directory do
      add_composer_json!
      set_x_sendfile_config!

      app.setup!
      app.push_with_retry!
    end

    assert(app.output).to_not match(%r{you do not have `apache` installed on this app})
  ensure
    app.teardown! if app
  end

  def set_x_sendfile_config!
    run!(%Q{echo "config.action_dispatch.x_sendfile_header = 'X-Sendfile'" > config/initializers/sendfile.rb})
    run!(%Q{git add -A; git commit -m 'changing config'})
  end

  # Puts apache on the path
  def add_composer_json!
    run!('echo {} > composer.json')
    run!(%Q{git add -A; git commit -m 'Adding apache'})
  end
end
