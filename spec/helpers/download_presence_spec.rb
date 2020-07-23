require "spec_helper"

describe LanguagePack::Helpers::DownloadPresence do
  it "knows if exists on the next stack" do
    download = LanguagePack::Helpers::DownloadPresence.new(
      'ruby-1.9.3.tgz',
      stacks: ['cedar-14', 'heroku-16', 'heroku-18']
    )

    download.call

    expect(download.next_stack(current_stack: "cedar-14")).to eq("heroku-16")
    expect(download.next_stack(current_stack: "heroku-16")).to eq("heroku-18")
    expect(download.next_stack(current_stack: "heroku-18")).to be_falsey

    expect(download.exists_on_next_stack?(current_stack:"cedar-14")).to be_truthy
  end

  it "detects when a package is present on higher stacks" do
    download = LanguagePack::Helpers::DownloadPresence.new(
      'ruby-2.6.5.tgz',
      stacks: ['cedar-14', 'heroku-16', 'heroku-18']
    )

    download.call

    expect(download.exists?).to eq(true)
    expect(download.valid_stack_list).to eq(['cedar-14', 'heroku-16', 'heroku-18'])

    expect(download.exists_on_next_stack?(current_stack: "heroku-16")).to be_truthy
    expect(download.next_stack(current_stack: "heroku-16")).to eq("heroku-18")
  end

  it "detects when a package is not present on higher stacks" do
    download = LanguagePack::Helpers::DownloadPresence.new(
      'ruby-1.9.3.tgz',
      stacks: ['cedar-14', 'heroku-16', 'heroku-18']
    )

    download.call

    expect(download.exists?).to eq(true)
    expect(download.valid_stack_list).to eq(['cedar-14'])
  end

  it "detects when a package is present on two stacks but not a third" do
    download = LanguagePack::Helpers::DownloadPresence.new(
      'ruby-2.3.0.tgz',
      stacks: ['cedar-14', 'heroku-16', 'heroku-18']
    )

    download.call

    expect(download.exists?).to eq(true)
    expect(download.valid_stack_list).to eq(['cedar-14', 'heroku-16'])
  end

  it "detects when a package does not exist" do
    download = LanguagePack::Helpers::DownloadPresence.new(
      'does-not-exist.tgz',
      stacks: ['cedar-14', 'heroku-16', 'heroku-18']
    )

    download.call

    expect(download.exists?).to eq(false)
    expect(download.valid_stack_list).to eq([])
  end

  it "detects default ruby version" do
    download = LanguagePack::Helpers::DownloadPresence.new(
      "#{LanguagePack::RubyVersion::DEFAULT_VERSION}.tgz",
    )

    download.call

    expect(download.exists?).to eq(true)
    expect(download.valid_stack_list).to include(LanguagePack::Helpers::DownloadPresence::STACKS.last)
  end

  it "handles the current stack not being in the known stacks list" do
    download = LanguagePack::Helpers::DownloadPresence.new(
      "#{LanguagePack::RubyVersion::DEFAULT_VERSION}.tgz",
    )

    download.call
    
    expect(download.supported_stack?(current_stack: "unknown-stack")).to be_falsey
    expect(download.next_stack(current_stack: "unknown-stack")).to be_nil
    expect(download.exists_on_next_stack?(current_stack:"unknown-stack")).to be_falsey
  end
end
