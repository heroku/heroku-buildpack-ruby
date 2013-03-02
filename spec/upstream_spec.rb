require "spec_helper"

describe "upstream Heroku repository" do
  it "doesn't have any new commits that we don't have" do
    heroku_latest_sha = `git ls-remote https://github.com/heroku/heroku-buildpack-ruby.git | head -1 | cut -f 1`
    system("git log --oneline -1 #{heroku_latest_sha}").should be_true
  end
end