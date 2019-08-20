require_relative '../spec_helper'

describe "Rails 6" do
  it "should detect successfully" do
    Hatchet::App.new('rails6-basic').in_directory do
      expect(LanguagePack::Rails5.use?).to eq(false)
    end
    Hatchet::App.new('rails6-basic').in_directory do
      expect(LanguagePack::Rails6.use?).to eq(true)
    end
  end
end
