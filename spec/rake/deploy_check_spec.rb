require "spec_helper"
require "rake/deploy_check"

describe "A helper class for deploying" do
  describe "tests that hit github" do
    it "know remote tags" do
      deploy = DeployCheck.new(github: "heroku/heroku-buildpack-ruby")
      expect(deploy.remote_tag_array.class).to eq(Array)
      expect(deploy.remote_tag_array).to include("v218")
    end

    it "remote sha" do
      deploy = DeployCheck.new(github: "sharpstone/do_not_delete_or_modify")
      expect(deploy.remote_commit_sha).to eq("3a9ff6433a05560acfd06dda03a11605a96ae133")
    end

    it "local_commit_sha" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          run!("git clone https://github.com/sharpstone/default_ruby #{dir} 2>&1 && cd #{dir} && git checkout 6e642963acec0ff64af51bd6fba8db3c4176ed6e 2>&1 && git checkout -b mybranch 2>&1")
          deploy = DeployCheck.new(github: "heroku/heroku-buildpack-ruby")
          expect(deploy.local_commit_sha).to eq("6e642963acec0ff64af51bd6fba8db3c4176ed6e")
        end
      end
    end
  end

  describe "tests that do NOT hit github" do
    it "checks multiple things" do
      deploy = DeployCheck.new(github: "heroku/heroku-buildpack-ruby")
      deploy.instance_variable_set("@methods_called", [])

      def deploy.check_version!; @methods_called << :check_version! ;end
      def deploy.check_unstaged!; @methods_called << :check_unstaged! ;end
      def deploy.check_branch!; @methods_called << :check_branch! ;end
      def deploy.check_changelog!; @methods_called << :check_changelog! ;end
      def deploy.check_sync!; @methods_called << :check_sync! ;end

      deploy.check!

      methods_called = deploy.instance_variable_get("@methods_called")
      expect(methods_called).to include(:check_version!)
      expect(methods_called).to include(:check_unstaged!)
      expect(methods_called).to include(:check_branch!)
      expect(methods_called).to include(:check_changelog!)
      expect(methods_called).to include(:check_sync!)
    end

    it "checks version" do
      ["v123abc", "123", "V123"].each do |bad_version|
        deploy = DeployCheck.new(github: "heroku/heroku-buildpack-ruby", next_version: bad_version)
        expect {
          deploy.check_version!
        }.to raise_error(/Must look like a version/)
      end
    end

    it "checks local sha and remote sha match" do
      deploy = DeployCheck.new(github: "heroku/heroku-buildpack-ruby")
      expect {
        deploy.check_sync!(local_sha: "a", remote_sha: "not a")
      }.to raise_error(/Must be in-sync/)

      deploy = DeployCheck.new(github: "heroku/heroku-buildpack-ruby")
      deploy.check_sync!(
        local_sha: "cbe100933b1e50953f0da35aafc50374ae2a31f9",
        remote_sha: "cbe100933b1e50953f0da35aafc50374ae2a31f9"
      )
    end

    it "github url" do
      deploy = DeployCheck.new(github: "heroku/heroku-buildpack-ruby")
      expect(deploy.github_url).to eq("https://github.com/heroku/heroku-buildpack-ruby")
    end

    it "knows the next version" do
      deploy = DeployCheck.new(github: "heroku/heroku-buildpack-ruby", next_version: "v123")

      def deploy.remote_tag_array; [ "v123" ] ; end

      expect(deploy.tag_exists_on_remote?).to be_truthy

      deploy = DeployCheck.new(github: "heroku/heroku-buildpack-ruby", next_version: "v124")

      def deploy.remote_tag_array; [ "v123" ] ; end

      expect(deploy.tag_exists_on_remote?).to be_falsey
    end

    it "checks remote tags for existance" do
      deploy = DeployCheck.new(github: "heroku/heroku-buildpack-ruby")

      def deploy.remote_tag_array; [ "v123" ] ; end

      expect(deploy.next_version).to eq("v124")
    end

    it "checks unstaged" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          deploy = DeployCheck.new(github: "heroku/heroku-buildpack-ruby")
          run!("echo 'blerg' >> foo.txt")
          run!("git init .; git add . ; git commit -m first")
          deploy.check_unstaged!

          run!("echo 'foo' >> foo.txt")
          expect { deploy.check_unstaged! }.to raise_error(/Must have all changes committed/)
        end
      end
    end

    it "checks branch" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          deploy = DeployCheck.new(github: "heroku/heroku-buildpack-ruby")
          run!("echo 'blerg' >> foo.txt")
          run!("git init .; git add . ; git commit -m first")
          run!("git checkout -B main")
          deploy.check_branch!

          expect { deploy.check_branch!("not_main") }.to raise_error(/Must be on main branch/)
        end
      end
    end

    it "checks CHANGELOG" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          deploy = DeployCheck.new(github: "heroku/heroku-buildpack-ruby", next_version: "v999")
          run!("touch CHANGELOG.md")
          expect {
            deploy.check_changelog!
          }.to raise_error(/Expected CHANGELOG.md to include v999/)

          run!("echo '## v999' >> CHANGELOG.md")
          deploy.check_changelog!
        end
      end
    end
  end
end
