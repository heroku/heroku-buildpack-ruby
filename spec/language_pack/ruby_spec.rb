require 'spec_helper'

describe LanguagePack::Ruby do

  describe '.use?' do

    context 'a ruby app' do
      let(:app_dir) { 'spec/support/ruby_app' }

      it "determines that it's a ruby app" do
        in_app_dir { expect(LanguagePack::Ruby.use?).to be_true }
      end
    end

    context 'a non-ruby app' do

      let(:app_dir) { 'spec/support/non_ruby_app' }

      it "determines that it's not a ruby app" do
        in_app_dir { expect(LanguagePack::Ruby.use?).to be_false }
      end
    end

  end

end
