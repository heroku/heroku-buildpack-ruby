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

  def cache_to_app(dir: , force:)
    copy(@cache_base.join(dir), @app_path.join(dir), force: force)
  end

  # removes the the specified path from the cache
  # @param [String] relative path from the cache_base
  def clear(path)
    target = @cache_base.join(path)
    target.exist? && target.rmtree
  end

  # Overwrite cache contents
  # When called the cache destination will be cleared and the new contents coppied over
  # This method is perferable as LanguagePack::Cache#add can cause accidental cache bloat.
  #
  # @param [String] path of contents to store. it will be stored using this a relative path from the cache_base.
  # @param [String] relative path to store the cache contents, if nil it will assume the from path
  def store(from, path = nil)
    path ||= from
    clear(path)
    copy(from, @cache_base.join(path), force: true)
  end

  # Adds file to cache without clearing the destination
  # Use LanguagePack::Cache#store to avoid accidental cache bloat
  def add(from, path = nil)
    path ||= from
    copy(from, @cache_base.join(path), force: true)
  end

  # load cache contents
  # @param [String] relative path of the cache contents
  # @param [String] path of where to store it locally, if nil, assume same relative path as the cache contents
  def load(path, dest = nil)
    dest ||= path
    copy(@cache_base.join(path), dest, force: true)
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

  # copy contents between to places in the cache
  # @param [String] source cache directory
  # @param [String] destination directory
  def cache_copy(from,to)
    copy(@cache_base.join(from), @cache_base.join(to), force: true)
  end

  # check if the cache content exists
  # @param [String] relative path of the cache contents
  # @param [Boolean] true if the path exists in the cache and false if otherwise
  def exists?(path)
    File.exist?(@cache_base.join(path))
  end
end
