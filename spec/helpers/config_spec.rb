require 'spec_helper'

describe "Boot Strap Config" do
  it "matches toml config" do
    require 'toml-rb'
    config = TomlRB.load_file("buildpack.toml")
    bootstrap_version = config["buildpack"]["ruby_version"]
    expect(bootstrap_version).to eq(LanguagePack::RubyVersion::BOOTSTRAP_VERSION_NUMBER)

    expect(`ruby -v`).to match(Regexp.escape(LanguagePack::RubyVersion::BOOTSTRAP_VERSION_NUMBER))

    ci_task = Pathname(".github").join("workflows").join("hatchet_app_cleaner.yml").read
    ci_task_yml = YAML.load(ci_task)
    task = ci_task_yml["jobs"]["hatchet-app-cleaner"]["steps"].detect {|step| step["uses"].match?(/ruby\/setup-ruby/)} or raise "Not found"
    expect(task["with"]["ruby-version"]).to match(LanguagePack::RubyVersion::BOOTSTRAP_VERSION_NUMBER)
  end
end
