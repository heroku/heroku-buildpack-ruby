require 'securerandom'
require "language_pack"
require "language_pack/rails5"
require "language_pack/helpers/yarn_installer"

class LanguagePack::Rails51 < LanguagePack::Rails5
  # @return [Boolean] true if it's a Rails 5.x app
  def self.use?
    instrument "rails51.use" do
      rails_version = bundler.gem_version('railties')
      return false unless rails_version
      is_rails = rails_version >= Gem::Version.new('5.1.x') &&
                 rails_version <  Gem::Version.new('6.0.0')
      return is_rails
    end
  end

  def initialize(build_path, cache_path=nil)
    super(build_path, cache_path)
    @yarn_installer    = LanguagePack::YarnInstaller.new(build_path, cache_path)
    @build_path = build_path
    puts "Build path = #{build_path}"
    puts "cache path = #{cache_path}"
  end

  def compile
    instrument "rails51.compile" do
      super
      allow_git do
        puts "installing yarn"
        puts @node_installer.install
        puts @yarn_installer.install
        puts "installing yarn done"
        install_node_packages
        run_webpack_compile_rake_task
      end
    end
  end

  def install_node_packages
    puts "installing node packages"
    puts "PWD : #{`pwd`}"
    puts `#{@build_path}/bin/yarn install`
    puts "installing node packages done"
  end

  def run_webpack_compile_rake_task
    instrument 'ruby.run_webpack_compile_rake_task' do

      compile = rake.task("webpacker:compile")
      return true unless compile.is_defined?

      topic "compiling webpacks"
      compile.invoke(env: rake_env)
      if compile.success?
        puts "Wepacker compile completed (#{"%.2f" % compile.time}s)"
      else
        log "webpacker_compile", :status => "failure"
        msg = "webpacker compile failed.\n"
      end
    end
  end

end
