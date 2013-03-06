require "spec_helper"
require "webmock/rspec"

describe LanguagePack::PackageFetcher do

  let(:fake_class) { Class.new { include LanguagePack::PackageFetcher } }
  let(:filename) { "my-favorite-package.tgz" }

  subject { fake_class.new }

  describe "#fetch_package" do
    context "when the package is found in the buildpack_cache" do
      before do
        subject.should_receive(:fetch_from_buildpack_cache).with(filename) { true }
        subject.should_not_receive(:fetch_from_blobstore)
        subject.should_not_receive(:fetch_from_curl)
      end

      it "stops after successfully retrieving from from cache" do
        subject.fetch_package(filename).should be_true
      end
    end

    context "when the package is not found in the buildpack_cache, but found in the blobstore" do
      before do
        subject.should_receive(:fetch_from_buildpack_cache).with(filename) { false }
        subject.should_receive(:fetch_from_blobstore).with(filename) { true }
        subject.should_not_receive(:fetch_from_curl)
      end

      it "stops after successfully retrieving from the blobstore" do
        subject.fetch_package(filename).should be_true
      end
    end

    context "when the package is not found in the buildpack_cache, nor the blobstore, but found via curl" do
      before do
        subject.should_receive(:fetch_from_buildpack_cache).with(filename) { false }
        subject.should_receive(:fetch_from_blobstore).with(filename) { false }
        subject.should_receive(:fetch_from_curl).with(filename) { true }
      end

      it "stops after successfully retrieving from the blobstore" do
        subject.fetch_package(filename).should be_true
      end
    end

    context "when the package is not found anywhere" do
      before do
        subject.should_receive(:fetch_from_buildpack_cache).with(filename) { false }
        subject.should_receive(:fetch_from_blobstore).with(filename) { false }
        subject.should_receive(:fetch_from_curl).with(filename) { false }
      end

      it "returns false" do
        subject.fetch_package(filename).should be_false
      end
    end
  end

  describe "#fetch_from_buildpack_cache" do

    it "should default the buildpack_cache_dir" do
      subject.buildpack_cache_dir.should == "/var/vcap/packages/buildpack_cache"
    end

    describe "copying from a test cache dir" do
      before do
        subject.buildpack_cache_dir = File.expand_path(File.join(File.dirname(__FILE__), "../fixtures/fake_buildpack_cache"))
      end

      context "when the file exists" do
        after { FileUtils.rm(filename) }

        it "copies the file to the current directory and returns true" do
          File.exists?(filename).should be_false
          subject.send(:fetch_from_buildpack_cache, filename).should be_true
          File.exists?(filename).should be_true
        end
      end

      context "when the file doesn't exist" do
        it "returns false" do
          subject.send(:fetch_from_buildpack_cache, "unknown-package.tgz").should be_false
        end
      end
    end
  end

  describe "#fetch_from_blobstore" do

    after { FileUtils.rm(filename) if File.exist?(filename) }

    let(:filename) { "ruby-1.9.3.tgz" }
    let(:sha) { "9160b6a5b1e66ad9bcd0f200b8be15e91d16c7c7" }
    let(:expected_url) { "http://blob.cfblob.com/rest/objects/4e4e78bca61e121004e4e7d51d950e0510096a910e5a?expires=1893484800&signature=+1Tod4mmEt4BG9j/1C6rYy6x4kw=&uid=bb6a0c89ef4048a8a0f814e25385d1c5/user1" }

    it "downloads the package and returns true" do
      response_body = "{\"hello\": \"there\"}"
      stub_request(:get, expected_url).to_return :status => 200, :body => response_body
      subject.stub(:file_checksum).and_return(sha)

      subject.send(:fetch_from_blobstore, filename).should be_true
      File.exists?(filename).should be_true
      File.read(filename).should == response_body
    end

    it "returns false if object is not found" do
      stub_request(:get, expected_url).to_return :status => 404, :body => "NOT FOUND"
      subject.send(:fetch_from_blobstore, filename).should be_false
    end

    it "returns false if oid, sig, or sha are missing" do
      subject.send(:fetch_from_blobstore, "unknown-package.tgz").should be_false
    end

    it "raises an Error if SHA is mismatched" do
      stub_request(:get, expected_url).to_return :status => 200, :body => "Whatever"
      subject.stub(:file_checksum).and_return("blajejs")
      subject.send(:fetch_from_blobstore, filename).should be_false
    end
  end

  describe "#fetch_from_curl" do
    before do
      subject.should_receive(:run).with("curl https://s3.amazonaws.com/heroku-buildpack-ruby/#{filename} -s -o #{filename}")
    end

    it "successfully downloads the file using curl and returns true" do
      File.should_receive(:exist?).with(filename) { true }
      subject.send(:fetch_from_curl, filename).should be_true
    end

    it "fails to downloads the file using curl and returns false" do
      File.should_receive(:exist?).with(filename) { false }
      subject.send(:fetch_from_curl, filename).should be_false
    end
  end
end


