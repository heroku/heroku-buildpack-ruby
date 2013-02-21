require 'spec_helper'

describe LanguagePack::Ruby do

  let(:app_dir) { 'spec/support/ruby_app' }

  let!(:app_work) { Dir.mktmpdir }
  let!(:cache_dir) { Dir.mktmpdir }
  let!(:cwd) { Dir.pwd }

  before :each do
    FileUtils.cp_r "#{app_dir}/.", app_work
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
      let(:app_dir) { 'spec/support/non_ruby_app' }

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

      let(:ruby_blob) {
        [("4e4e78bca31e122204e4e9863b1b740510096a2b8696"),
          ("/45mjMKhckPxTUhNBeexTFAALA4="),
          ("84134cbc0e3345244a039c8cb43fdbb056bc2d34"),
          ("ruby-1.9.2.tgz")]
      }

      let(:ruby_build_blob) {
        [("4e4e78bca21e122204e4e9863926b10510096b389b02"),
          ("HZ+96UdoJr324YZHcAcSjwkMq2I="),
          ("6f17cd95878781334be656460ef4873f57c88643"),
          ("ruby-build-1.9.2.tgz")]
      }

      let(:build_ruby) { true }

      before :each do
        subject.stub(:build_ruby?) { build_ruby }
        subject.stub(:allow_git)
        subject.stub(:ruby_version) { 'ruby-1.9.2' }
        subject.stub(:run).with("ruby -e \"require 'rbconfig';puts \\\"vendor/bundle/\#{RUBY_ENGINE}/\#{RbConfig::CONFIG['ruby_version']}\\\"\"") { '' }
      end

      context 'when building ruby' do

        it 'downloads and untars the ruby and ruby-build blobs' do
          subject.stub(:download_blob).with(*ruby_blob)
          subject.stub(:download_blob).with(*ruby_build_blob)
          subject.stub(:run).with('tar zxf ruby-1.9.2.tgz') { %x{true} }
          subject.stub(:run).with('tar zxf ruby-build-1.9.2.tgz') { %x{true} }
          subject.stub(:run).with("ln -s ../vendor/ruby-1.9.2/bin/a bin")
          subject.stub(:run).with("ln -s ../vendor/ruby-1.9.2/bin/b bin")

          subject.compile
        end

      end

      context 'when not building ruby' do

        let(:build_ruby) { false }

        it 'downloads and untars the ruby blob' do
          subject.stub(:download_blob).with(*ruby_blob)
          subject.stub(:run).with('tar zxf ruby-1.9.2.tgz') { %x{true} }
          subject.stub(:run).with("ln -s ../vendor/ruby-1.9.2/bin/a bin")
          subject.stub(:run).with("ln -s ../vendor/ruby-1.9.2/bin/b bin")

          subject.compile
        end

      end

      context 'creating bin dir' do

        before :each do
          subject.stub(:download_blob)
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

        it 'creates the slug vendor jvm directory' do
        end

        it 'downloads the jvm' do
        end

        context 'creating bin dir' do
          it 'creates a bin dir' do
          end

          it 'symlinks vendored binaries into bin' do
          end

        end

      end

      context 'setting up the language pack environment' do

        it 'sets environment variables' do
        end

      end

      context 'setting up profiled' do

        it 'creates the correct profiled file' do
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

          subject.stub(:run).with("curl https://s3.amazonaws.com/heroku-buildpack-ruby/a.tgz -s -o - | tar xzf -")
          subject.stub(:run).with("curl https://s3.amazonaws.com/heroku-buildpack-ruby/b.tgz -s -o - | tar xzf -")
          subject.stub(:run).with("curl https://s3.amazonaws.com/heroku-buildpack-ruby/c.tgz -s -o - | tar xzf -")

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

          subject.stub(:run).with('chmod 755 bin/a')
          subject.stub(:run).with('chmod 755 bin/b')

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
          subject.stub(:install_libyaml)
          subject.stub(:run).with('pwd') { '' }
          subject.stub(:pipe) { %x{true} }
        end

        it 'installs libyaml' do
          subject.stub(:run).with("curl https://s3.amazonaws.com/heroku-buildpack-ruby/libyaml-0.1.4.tgz -s -o - | tar xzf -")
          subject.compile
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
          subject.stub(:run).with("curl https://s3.amazonaws.com/heroku-buildpack-ruby/a.tgz -s -o - | tar xzf -")
          subject.stub(:run).with("curl https://s3.amazonaws.com/heroku-buildpack-ruby/b.tgz -s -o - | tar xzf -")
          subject.stub(:run).with("curl https://s3.amazonaws.com/heroku-buildpack-ruby/c.tgz -s -o - | tar xzf -")

          subject.stub(:run).with('chmod +x bin/c')
          subject.stub(:run).with('chmod +x bin/d')

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
          subject.stub(:run, "env PATH=$PATH bundle exec rake assets:precompile --dry-run") { '' }

          subject.compile
        end

      end

    end

  end

end
