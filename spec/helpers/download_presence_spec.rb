require "spec_helper"

describe LanguagePack::Helpers::DownloadPresence do
  it "handles multi-arch transitions for files that exist" do
    download = LanguagePack::Helpers::DownloadPresence.new(
      multi_arch_stacks: ["heroku-24"],
      file_name: 'ruby-3.1.4.tgz',
      stacks: ["heroku-22", "heroku-24"],
      arch: "amd64"
    )

    download.call

    expect(download.next_stack(current_stack: "heroku-22")).to eq("heroku-24")
    expect(download.next_stack(current_stack: "heroku-24")).to be_falsey

    expect(download.exists_on_next_stack?(current_stack:"heroku-22")).to be_truthy
  end

  it "handles multi-arch transitions for files that do not exist" do
    download = LanguagePack::Helpers::DownloadPresence.new(
      multi_arch_stacks: ["heroku-24"],
      file_name: 'ruby-3.0.5.tgz',
      # Heroku 20 is not longer supported however heroku-22 and heroku-24
      # have identical Ruby versions supported, this test can be updated to
      # use heroku-24 and heroku-26 (when that stack is released)
      stacks: ["heroku-20", "heroku-24"],
      arch: "amd64"
    )

    download.call

    expect(download.next_stack(current_stack: "heroku-20")).to eq("heroku-24")
    expect(download.next_stack(current_stack: "heroku-24")).to be_falsey

    expect(download.exists_on_next_stack?(current_stack:"heroku-20")).to be_falsey
  end

  it "knows if exists on the next stack" do
    download = LanguagePack::Helpers::DownloadPresence.new(
      multi_arch_stacks: ["heroku-24"],
      file_name: "#{LanguagePack::RubyVersion::DEFAULT_VERSION}.tgz",
      stacks: ['heroku-22', 'heroku-24'],
      arch: "amd64"
    )

    download.call

    expect(download.next_stack(current_stack: "heroku-22")).to eq("heroku-24")
    expect(download.next_stack(current_stack: "heroku-24")).to be_falsey

    expect(download.exists_on_next_stack?(current_stack:"heroku-22")).to be_truthy
  end

  it "detects when a package is present on two stacks but not a third" do
    download = LanguagePack::Helpers::DownloadPresence.new(
      multi_arch_stacks: [],
      file_name: 'ruby-2.3.0.tgz',
      stacks: ['cedar-14', 'heroku-16', 'heroku-18'],
      arch: nil
    )

    download.call

    expect(download.exists?).to eq(true)
    expect(download.valid_stack_list).to eq(['cedar-14', 'heroku-16'])
  end

  it "detects when a package does not exist" do
    download = LanguagePack::Helpers::DownloadPresence.new(
      multi_arch_stacks: [],
      file_name: 'does-not-exist.tgz',
      stacks: ['heroku-22', 'heroku-24'],
      arch: nil
    )

    download.call

    expect(download.exists?).to eq(false)
    expect(download.valid_stack_list).to eq([])
  end

  it "detects default ruby version" do
    download = LanguagePack::Helpers::DownloadPresence.new(
      multi_arch_stacks: ['heroku-24'],
      file_name: "#{LanguagePack::RubyVersion::DEFAULT_VERSION}.tgz",
      arch: "amd64"
    )

    download.call

    expect(download.exists?).to eq(true)
    expect(download.valid_stack_list).to include(LanguagePack::Helpers::DownloadPresence::STACKS.last)
  end

  it "handles the current stack not being in the known stacks list" do
    download = LanguagePack::Helpers::DownloadPresence.new(
      multi_arch_stacks: [],
      file_name: "#{LanguagePack::RubyVersion::DEFAULT_VERSION}.tgz",
      arch: nil
    )

    download.call

    expect(download.supported_stack?(current_stack: "unknown-stack")).to be_falsey
    expect(download.next_stack(current_stack: "unknown-stack")).to be_nil
    expect(download.exists_on_next_stack?(current_stack:"unknown-stack")).to be_falsey
  end
end
