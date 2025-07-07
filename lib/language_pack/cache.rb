require "pathname"
require "language_pack"

# Manipulates and handles contents of the cache directory
#
# In a build, the cache directory is passed to the buildpack. This
# class is responsible for moving folders/files in that cache directory
# into their correct runtime (or build) needed location at the start of the build.
# It is then responsible for storing the updated contents at the runtime (or build)
# location and putting them back into the cache directory which will be passed to the
# next build.
class LanguagePack::Cache
  # @param [String] path to the cache store
  def initialize(cache_path:, app_path: , stack: ENV["STACK"])
    @stack = stack
    @app_path = Pathname(app_path)
    @cache_base = Pathname(cache_path)
  end

  # Move cache directory contents into application directory
  def cache_to_app(dir: , force:, rename: nil)
    copy(@cache_base.join(dir), @app_path.join(rename || dir), force: force)
  end

  def app_to_cache(dir: , force:, rename: nil)
    copy(@app_path.join(dir), @cache_base.join(rename || dir), force: force)
  end

  def cache_to_cache(dir: , force:, rename: nil)
    copy(@cache_base.join(dir), @cache_base.join(rename || dir), force: force)
  end

  # removes the the specified path from the cache
  # @param [String] relative path from the cache_base
  def clear(path)
    target = @cache_base.join(path)
    target.exist? && target.rmtree
  end

  # check if the cache content exists
  # @param [String] relative path of the cache contents
  # @param [Boolean] true if the path exists in the cache and false if otherwise
  def exists?(path)
    @cache_base.join(path).exists?
  end

  # copy cache contents
  # @param [String] source directory
  # @param [String] destination directory
  private def copy(from, to, force: )
    return false unless File.exist?(from)

    if force
      options = "-a"
    else
      case @stack
      when "heroku-22"
        options = "-a -n"
      else
        options = "-a --update=none"
      end
    end

    FileUtils.mkdir_p File.dirname(to)
    command = "cp #{options} #{from}/. #{to}"
    system(command)
    raise "Command failed `#{command}`" unless $?
  end
end
