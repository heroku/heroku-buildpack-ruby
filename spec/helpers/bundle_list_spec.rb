
require 'spec_helper'

describe "Bundle list" do
  it "parses bundle list output" do
    output = <<~EOF
      Gems included by the bundle:
        * actioncable (6.1.4.1)
        * actionmailbox (6.1.4.1)
        * actionmailer (6.1.4.1)
        * actionpack (6.1.4.1)
        * actiontext (6.1.4.1)
        * actionview (6.1.4.1)
        * activejob (6.1.4.1)
        * activemodel (6.1.4.1)
        * activerecord (6.1.4.1)
        * activestorage (6.1.4.1)
        * activesupport (6.1.4.1)
        * addressable (2.8.0)
        * ast (2.4.2)
        * railties (6.1.4.1)
      Use `bundle info` to print more detailed information about a gem
    EOF

    bundle_list = LanguagePack::Helpers::BundleList.new(
      output: output
    )
    expect(bundle_list.has_gem?("railties")).to be_truthy
    expect(bundle_list.gem_version("railties")).to eq(Gem::Version.new("6.1.4.1"))
    expect(bundle_list.has_gem?("nope")).to be_falsey

    expect(bundle_list.length).to eq(14)
  end

  it "handles git SHA gems" do
    output = <<~EOF
      Gems included by the bundle:
        * railties (6.1.4.1 asdf1)
      Use `bundle info` to print more detailed information about a gem
    EOF

    bundle_list = LanguagePack::Helpers::BundleList.new(
      output: output
    )
    expect(bundle_list.has_gem?("railties")).to be_truthy
    expect(bundle_list.gem_version("railties")).to eq(Gem::Version.new("6.1.4.1"))
    expect(bundle_list.has_gem?("nope")).to be_falsey

    expect(bundle_list.length).to eq(1)
  end
end
