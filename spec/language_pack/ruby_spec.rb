require 'spec_helper'

describe LanguagePack::Ruby do

  before :each do
    @cwd = Dir.pwd
  end

  after :each do
    Dir.chdir @cwd
  end

  let(:build_path) { 'spec/support/ruby_app' }

  subject { LanguagePack::Ruby.new(build_path) }

  describe '.use?' do

    context 'a ruby app' do
      its(:'class.use?') { should be_true }
    end

    context 'a non-ruby app' do
      let(:build_path) { 'spec/support/non_ruby_app' }

      its(:'class.use?') { should be_false }
    end
  end

  describe '#name' do

    its(:name) { should == 'Ruby' }

  end

  describe '#default_addons' do

    let(:pg_bundled) { true }

    before :each do
      subject.stub(:gem_is_bundled?).with('pg') { pg_bundled }
    end

    context 'when pg gem is bundled' do
      its(:default_addons) { should == ['shared-database:5mb'] }
    end

    context 'when pg gem is not bundled' do
      let(:pg_bundled) { false }

      its(:default_addons) { should be_empty }
    end
  end

  describe '#default_config_vars' do

    let(:jruby) { false }

    before :each do
      subject.stub(
        :ruby_version_jruby? => jruby,
        :default_path => 'default path',
        :slug_vendor_base => 'slug vendor base',
        :default_java_opts => 'default java opts',
        :default_jruby_opts => 'default jruby opts'
      )
    end

    context 'ruby is jruby' do
      let(:jruby) { true }

      it 'sets the correct config vars' do
        expect(subject.default_config_vars).to eq({
          'LANG' => 'en_US.UTF-8',
          'PATH' => 'default path',
          'GEM_PATH' => 'slug vendor base',
          'JAVA_OPTS' => 'default java opts',
          'JRUBY_OPTS' => 'default jruby opts'
        })
      end
    end

    context ' version is not jruby ' do
      it ' sets the correct config vars ' do
        expect(subject.default_config_vars).to eq({
          'LANG' => 'en_US.UTF-8',
          'PATH' => 'default path',
          'GEM_PATH' => 'slug vendor base',
        })
      end
    end

  end

end
