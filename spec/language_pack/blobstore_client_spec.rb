require "spec_helper"
require "webmock/rspec"

describe LanguagePack::BlobstoreClient do

  let(:fake_class) { Class.new { include LanguagePack::BlobstoreClient } }
  let(:expected_url) { "http://blob.cfblob.com/rest/objects/#{oid}?expires=1893484800&signature=#{sig}&uid=bb6a0c89ef4048a8a0f814e25385d1c5/user1" }
  let(:oid) { "12345" }
  let(:sig) { "123" }
  let(:sha) { "5678" }
  subject { fake_class.new }


  it "can download a blob to a specified location" do
    response_body = "{\"hello\": \"there\"}"
    stub_request(:get, expected_url).to_return :status => 200, :body => response_body
    subject.stub(:file_checksum).and_return(sha)
    Dir.mktmpdir do |tmpdir|
      downloaded_file = "#{tmpdir}/myfile"
      subject.download_blob(oid, sig, sha, downloaded_file)
      File.exists?(downloaded_file).should be_true
      File.read(downloaded_file).should == response_body
    end
  end


  it "raises an Error if object is not found" do
    stub_request(:get, expected_url).to_return :status => 404, :body => "NOT FOUND"
    Dir.mktmpdir do |tmpdir|
      expect { subject.download_blob(oid, sig, sha, "#{tmpdir}/myfile") }.to raise_error
      "Could not fetch object, 404/NOT FOUND"
    end
  end

  it "raises an Error if OID is nil" do
    Dir.mktmpdir do |tmpdir|
      expect { subject.download_blob(nil, sig, sha, "#{tmpdir}/myfile") }.to raise_error
      "A valid object id, signature, and SHA are required"
    end
  end

  it "raises an Error if sig is nil" do
    Dir.mktmpdir do |tmpdir|
      expect { subject.download_blob(oid, nil, sha, "#{tmpdir}/myfile") }.to raise_error
      "A valid object id and signature, and SHA are required"
    end
  end

  it "raises an Error if SHA is nil" do
    Dir.mktmpdir do |tmpdir|
      expect { subject.download_blob(oid, sig, nil, "#{tmpdir}/myfile") }.to raise_error
      "A valid object id and signature, and SHA are required"
    end
  end

  it "raises an Error if SHA is mismatched" do
    stub_request(:get, expected_url).to_return :status => 200, :body => "Whatever"
    subject.stub(:file_checksum).and_return("blajejs")
    Dir.mktmpdir do |tmpdir|
      expect { subject.download_blob(oid, sig, sha, "#{tmpdir}/myfile") }.to raise_error
      "Checksum mismatch for downloaded blob"
    end
  end
end
