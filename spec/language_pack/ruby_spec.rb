require 'spec_helper'

describe LanguagePack::Ruby do

  let(:app_dir) { File.expand_path(File.join(File.dirname(__FILE__), '../support/ruby_app')) }

  let!(:app_work) { Dir.mktmpdir }
  let!(:cache_dir) { Dir.mktmpdir }
  let!(:cwd) { Dir.pwd }

  before :each do
    FileUtils.cp_r "#{app_dir}/.", app_work
    subject.stub(:ruby_versions) { ["ruby-1.9.3", "ruby-1.9.2", "ruby-1.8.7"] }
  end

  after :each do
    FileUtils.rm_rf app_work
    FileUtils.rm_rf cache_dir
    Dir.chdir cwd
  end

  subject { LanguagePack::Ruby.new(app_work, cache_dir) }

  describe '.use?' do

    context 'a ruby app' do
      its(:'class.use?') { should be_true }
    end

    context 'a non-ruby app' do
      let(:app_dir) { File.expand_path(File.join(File.dirname(__FILE__), '../support/non_ruby_app')) }

      its(:'class.use?') { should be_false }
    end
  end

  describe ".gem_version" do
    it "does not crash" do
      LanguagePack::Ruby.should_receive(:fetch_package_and_untar).with("#{LanguagePack::Ruby::BUNDLER_GEM_PATH}.tgz")
      expect { LanguagePack::Ruby.gem_version('rake') }.to_not raise_error
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
      its(:default_addons) { should == ['heroku-postgresql:dev'] }
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

  describe '#default_process_types' do
    it 'sets the correct process types' do
      expect(subject.default_process_types).to eq({
        "rake" => "bundle exec rake",
        "console" => "bundle exec irb"
      })
    end
  end

  describe '#compile' do

    it 'removes vendor/bundle' do
      subject.stub(:install_ruby)
      subject.stub(:allow_git)

      expect(File.exist?(File.join(app_work, 'vendor', 'bundle'))).to be_true

      subject.compile

      expect(File.exist?(File.join(app_work, 'vendor', 'bundle'))).to be_false
    end

    context 'installing ruby' do

      let(:ruby_package) { "ruby-1.9.2.tgz" }

      let(:ruby_build_package) { "ruby-build-1.9.2.tgz" }

      let(:build_ruby) { true }

      before :each do
        subject.stub(:build_ruby?) { build_ruby }
        subject.stub(:allow_git)
        subject.stub(:ruby_version) { 'ruby-1.9.2' }
        subject.stub(:run).with("ruby -e \"require 'rbconfig';puts \\\"vendor/bundle/\#{RUBY_ENGINE}/\#{RbConfig::CONFIG['ruby_version']}\\\"\"") { '' }
      end

      context 'when building ruby' do

        it 'downloads and untars the ruby and ruby-build blobs' do
          subject.stub(:fetch_package_and_untar).with(ruby_package) { %x{true} }
          subject.stub(:fetch_package_and_untar).with(ruby_build_package) { %x{true} }
          subject.stub(:run).with("ln -s ../vendor/ruby-1.9.2/bin/a bin")
          subject.stub(:run).with("ln -s ../vendor/ruby-1.9.2/bin/b bin")

          subject.compile
        end

      end

      context 'when not building ruby' do

        let(:build_ruby) { false }

        it 'downloads and untars the ruby blob' do
          subject.should_receive(:fetch_package_and_untar).with(ruby_package) { %x{true} }
          subject.should_receive(:run).with("ln -s ../vendor/ruby-1.9.2/bin/a bin")
          subject.should_receive(:run).with("ln -s ../vendor/ruby-1.9.2/bin/b bin")

          subject.compile
        end

      end

      context 'creating bin dir' do

        before :each do
          subject.stub(:fetch_package)
          subject.stub(:run).with('tar zxf ruby-1.9.2.tgz') { %x{true} }
          subject.stub(:run).with('tar zxf ruby-build-1.9.2.tgz') { %x{true} }
        end

        it 'creates a bin dir' do
          subject.stub(:run).with("ln -s ../vendor/ruby-1.9.2/bin/a bin")
          subject.stub(:run).with("ln -s ../vendor/ruby-1.9.2/bin/b bin")

          subject.compile

          expect(File.exist?(File.join(app_work, 'bin'))).to be_true
        end

        it 'symlinks vendored binaries into bin' do
          subject.stub(:run).with("ln -s ../vendor/ruby-1.9.2/bin/a bin").and_call_original
          subject.stub(:run).with("ln -s ../vendor/ruby-1.9.2/bin/b bin").and_call_original

          subject.compile

          expect(File.symlink?(File.join(app_work, 'bin', 'a'))).to be_true
          expect(File.symlink?(File.join(app_work, 'bin', 'b'))).to be_true
        end

      end

      context 'installing the jvm' do

        let(:slug_vendor_jvm) { 'slug_vendor_jvm' }

        before :each do
          subject.stub(:ruby_version_jruby?) { true }
          subject.stub(:install_ruby)
          subject.stub(:fetch_package_and_untar).with('openjdk7-latest.tar.gz', 'http://heroku-jvm-langpack-java.s3.amazonaws.com')
          ENV.stub(:[]=)
        end

        it 'creates the slug vendor jvm directory' do
          subject.stub(:slug_vendor_jvm) { slug_vendor_jvm }

          subject.compile

          expect(File.directory?(slug_vendor_jvm)).to be_true
        end

        it 'downloads the jvm' do
          subject.compile
        end

        context 'creating bin dir' do

          before :each do
            subject.stub(:slug_vendor_jvm) { slug_vendor_jvm }
          end

          it 'creates a bin dir' do
            subject.compile

            expect(File.directory?('bin')).to be_true
          end

          it 'symlinks vendored binaries into bin' do
            FileUtils.mkdir_p File.join(slug_vendor_jvm, 'bin')
            FileUtils.touch File.join(slug_vendor_jvm, 'bin', 'a')
            FileUtils.touch File.join(slug_vendor_jvm, 'bin', 'b')

            subject.stub(:run).with("ln -s ../#{slug_vendor_jvm}/bin/a bin").and_call_original
            subject.stub(:run).with("ln -s ../#{slug_vendor_jvm}/bin/b bin").and_call_original

            subject.compile

            expect(File.symlink?(File.join('bin', 'a'))).to be_true
            expect(File.symlink?(File.join('bin', 'b'))).to be_true
          end

        end

      end

      context 'setting up the language pack environment' do

        let(:ruby_install_binstub_path) { 'ruby install binstub path' }
        let(:slug_vendor_base) { 'slug vendor base' }

        before :each do
          subject.stub(:install_ruby)
          subject.stub(:ruby_install_binstub_path) { ruby_install_binstub_path }
          subject.stub(:slug_vendor_base) { slug_vendor_base }
        end

        context 'when ruby is MRI' do

          it 'sets the environment variables' do
            ENV.should_receive(:[]=).with('GEM_HOME', slug_vendor_base)
            ENV.should_receive(:[]=).with('GEM_PATH', slug_vendor_base)
            ENV.should_receive(:[]=).with('PATH', /^#{ruby_install_binstub_path}/)

            subject.compile
          end
        end

        context 'when ruby is jruby' do
          it 'sets the environment variables' do
            subject.stub(:ruby_version_jruby?) { true }
            subject.stub(:install_jvm)

            ENV.should_receive(:[]=).with('GEM_HOME', slug_vendor_base)
            ENV.should_receive(:[]=).with('GEM_PATH', slug_vendor_base)
            ENV.should_receive(:[]=).with('PATH', /^#{ruby_install_binstub_path}/)

            if ENV['JAVA_OPTS']
              ENV.should_receive(:[]=).with('JAVA_OPTS', '-Xmx384m -Xss512k -XX:+UseCompressedOops -Dfile.encoding=UTF-8')
            else
              ENV.should_receive(:[]=).with('JAVA_OPTS', '-Xmx384m -Xss512k -XX:+UseCompressedOops -Dfile.encoding=UTF-8').twice
            end

            ENV.should_receive(:[]=).with('JRUBY_OPTS', '-Xcompile.invokedynamic=true') unless ENV['JRUBY_OPTS']

            subject.compile
          end

        end

      end

      context 'setting up profiled' do

        let(:slug_vendor_base) { 'slug_vendor_base' }
        let(:staging_environment_path) { 'staging_environment_path' }

        before :each do
          subject.stub(:install_ruby)
          subject.stub(:staging_environment_path) { staging_environment_path }
          subject.stub(:slug_vendor_base) { slug_vendor_base }
        end

        context 'when ruby is MRI' do

          before :each do
            subject.compile

            @ruby_profile = File.read('.profile.d/ruby.sh')
          end

          it 'writes the gem path to profiled' do
            expect(@ruby_profile).to include "GEM_PATH=\"$HOME/#{slug_vendor_base}:$GEM_PATH\""
          end

          it 'writes the lang to profiled' do
            expect(@ruby_profile).to include "LANG=${LANG:-en_US.UTF-8}"
          end

          it 'writes the path to profiled' do
            expect(@ruby_profile).to include "PATH=\"$HOME/bin:$HOME/#{slug_vendor_base}/bin:#{staging_environment_path}:$PATH\""
          end

        end

        context 'when ruby is jruby' do

          before :each do
            subject.stub(:ruby_version_jruby?) { true }
            subject.stub(:install_jvm)

            subject.compile

            @ruby_profile = File.read('.profile.d/ruby.sh')
          end

          it 'writes the gem path to profiled' do
            expect(@ruby_profile).to include "GEM_PATH=\"$HOME/#{slug_vendor_base}:$GEM_PATH\""
          end

          it 'writes the lang to profiled' do
            expect(@ruby_profile).to include "LANG=${LANG:-en_US.UTF-8}"
          end

          it 'writes the path to profiled' do
            expect(@ruby_profile).to include "PATH=\"$HOME/bin:$HOME/#{slug_vendor_base}/bin:#{staging_environment_path}:$PATH\""
          end

          it 'writes the java opts to profiled' do
            expect(@ruby_profile).to include "JAVA_OPTS=${JAVA_OPTS:--Xmx384m -Xss512k -XX:+UseCompressedOops -Dfile.encoding=UTF-8}"
          end

          it 'writes the jruby opts to profiled' do
            expect(@ruby_profile).to include "JRUBY_OPTS=${JRUBY_OPTS:--Xcompile.invokedynamic=true}"
          end
        end

      end

      context 'installing vendored gems' do

        let(:slug_vendor_base) { 'slug_vendor_base' }

        it 'downloads the gems' do
          subject.stub(:install_ruby)
          subject.stub(:allow_git).and_call_original
          subject.stub(:build_bundler)
          subject.stub(:slug_vendor_base) { slug_vendor_base }
          subject.stub(:install_binaries)
          subject.stub(:run_assets_precompile_rake_task)
          subject.stub(:gems) { %w{a b c} }

          subject.should_receive(:fetch_package_and_untar).with("a.tgz")
          subject.should_receive(:fetch_package_and_untar).with("b.tgz")
          subject.should_receive(:fetch_package_and_untar).with("c.tgz")

          subject.compile
        end

        it 'chmods the binaries' do
          subject.stub(:install_ruby)
          subject.stub(:allow_git).and_call_original
          subject.stub(:build_bundler)
          subject.stub(:slug_vendor_base) { "vendor/ruby-1.9.2" }
          subject.stub(:install_binaries)
          subject.stub(:run_assets_precompile_rake_task)
          subject.stub(:gems) { [] }

          subject.should_receive(:run).with('chmod 755 bin/a')
          subject.should_receive(:run).with('chmod 755 bin/b')

          subject.compile
        end

      end

      context 'building bundler' do

        let(:slug_vendor_base) { 'slug_vendor_base' }

        before :each do
          subject.stub(:install_ruby)
          subject.stub(:allow_git).and_call_original
          subject.stub(:install_language_pack_gems)
          subject.stub(:install_binaries)
          subject.stub(:run_assets_precompile_rake_task)
          subject.stub(:slug_vendor_base) { slug_vendor_base }
          subject.stub(:add_bundler_to_load_path)
          subject.stub(:syck_hack) { 'syck hack' }
          subject.stub(:run).with('env RUBYOPT="syck hack" bundle version') { '' }
          subject.stub(:load_bundler_cache)
          subject.stub(:run).with('pwd') { '' }
          subject.stub(:pipe) { %x{true} }
        end

        it 'removes vendor cache from the slug' do
          FileUtils.mkdir_p "#{slug_vendor_base}/cache"

          subject.compile

          expect(File.exist?("#{slug_vendor_base}/cache")).to be_false
        end

      end

      context 'creating database.yml' do

        it 'creates the file' do
          subject.stub(:install_ruby)
          subject.stub(:allow_git).and_call_original
          subject.stub(:install_language_pack_gems)
          subject.stub(:build_bundler)
          subject.stub(:install_binaries)
          subject.stub(:run_assets_precompile_rake_task)

          subject.compile

          expect(File.read('config/database.yml')).to eq <<-eos
<%

require 'cgi'
require 'uri'

begin
  uri = URI.parse(ENV["DATABASE_URL"])
rescue URI::InvalidURIError
  raise "Invalid DATABASE_URL"
end

raise "No RACK_ENV or RAILS_ENV found" unless ENV["RAILS_ENV"] || ENV["RACK_ENV"]

def attribute(name, value, force_string = false)
  if value
    value_string =
      if force_string
        '"' + value + '"'
      else
        value
      end
    "\#{name}: \#{value_string}"
  else
    ""
  end
end

adapter = uri.scheme
adapter = "postgresql" if adapter == "postgres"

database = (uri.path || "").split("/")[1]

username = uri.user
password = uri.password

host = uri.host
port = uri.port

params = CGI.parse(uri.query || "")

%>

<%= ENV["RAILS_ENV"] || ENV["RACK_ENV"] %>:
  <%= attribute "adapter",  adapter %>
  <%= attribute "database", database %>
  <%= attribute "username", username %>
  <%= attribute "password", password, true %>
  <%= attribute "host",     host %>
  <%= attribute "port",     port %>

<% params.each do |key, value| %>
  <%= key %>: <%= value.first %>
<% end %>
          eos
        end

      end

      context 'installing binaries' do

        it 'installs binaries' do
          subject.stub(:install_ruby)
          subject.stub(:allow_git).and_call_original
          subject.stub(:install_language_pack_gems)
          subject.stub(:build_bundler)
          subject.stub(:run_assets_precompile_rake_task)
          subject.stub(:binaries) { %w{a b c} }

          subject.should_receive(:fetch_package_and_untar).with("a.tgz")
          subject.should_receive(:fetch_package_and_untar).with("b.tgz")
          subject.should_receive(:fetch_package_and_untar).with("c.tgz")

          subject.should_receive(:run).with('chmod +x bin/c')
          subject.should_receive(:run).with('chmod +x bin/d')

          subject.compile
        end
      end

      context 'precompiling assets' do

        it 'runs the rake assets: precompile task' do
          subject.stub(:install_ruby)
          subject.stub(:allow_git).and_call_original
          subject.stub(:install_language_pack_gems)
          subject.stub(:build_bundler)
          subject.stub(:install_binaries)

          subject.should_receive(:run).with("env PATH=$PATH bundle exec rake assets:precompile --dry-run") { '' }

          subject.compile
        end

      end

    end

  end

end
