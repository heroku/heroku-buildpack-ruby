require 'securerandom'
require "language_pack"
require "language_pack/rails42"
require "language_pack/helpers/yarn_wrapper"

class LanguagePack::Rails5 < LanguagePack::Rails42
  # @return [Boolean] true if it's a Rails 5.x app
  def self.use?
    instrument "rails5.use" do
      rails_version = bundler.gem_version('railties')
      return false unless rails_version
      is_rails = rails_version >= Gem::Version.new('5.x') &&
                 rails_version <  Gem::Version.new('6.0.0')
      return is_rails
    end
  end

  def initialize(build_path, cache_path=nil)
    super(build_path, cache_path)
    @yarn_wrapper    = LanguagePack::Helpers::YarnWrapper.new
  end

  def compile
    instrument "rails5.compile" do
      super
      allow_git do
        # installs node, yarn, node modules if package.json and yarn.lock present.
        @yarn_wrapper.install_node_modules_and_dependencies
        run_webpack_compile_rake_task
      end
    end
  end

  def setup_profiled
    instrument 'setup_profiled' do
      super
      set_env_default "RAILS_LOG_TO_STDOUT", "enabled"
    end
  end

  def default_config_vars
    super.merge({
      "RAILS_LOG_TO_STDOUT" => "enabled"
    })
  end

  def install_plugins
    # do not install plugins, do not call super, do not warn
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
        error(msg)
      end
    end
  end
end
