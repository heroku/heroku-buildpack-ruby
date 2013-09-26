require 'spec_helper'

describe "Cleans Stale Files" do

  it "removes files if they go over the limit" do
    file_size = 1000
    Dir.mktmpdir do |dir|
      old_file = create_file_with_size_in(file_size, dir)
      sleep 1 # need mtime of files to be different
      new_file = create_file_with_size_in(file_size, dir)

      expect(old_file.exist?).to be_true
      expect(new_file.exist?).to be_true

      ::LanguagePack::Helpers::StaleFileCleaner.new(dir).clean_over(2*file_size - 50)

      expect(old_file.exist?).to be_false
      expect(new_file.exist?).to be_true
    end
  end

  it "leaves files if they are under the limit" do
    file_size = 1000
    Dir.mktmpdir do |dir|
      old_file = create_file_with_size_in(file_size, dir)
      sleep 1 # need mtime of files to be different
      new_file = create_file_with_size_in(file_size, dir)

      expect(old_file.exist?).to be_true
      expect(new_file.exist?).to be_true
      dir_size = File.stat(dir)

      ::LanguagePack::Helpers::StaleFileCleaner.new(dir).clean_over(2*file_size + 50)

      expect(old_file.exist?).to be_true
      expect(new_file.exist?).to be_true
    end
  end
end
