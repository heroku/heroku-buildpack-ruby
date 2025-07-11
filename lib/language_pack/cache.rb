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
  def initialize(cache_path:, app_path: , stack: ENV["STACK"], report: HerokuBuildReport::GLOBAL, experiment_enabled: false)
    @report = report
    @stack = stack
    @app_path = Pathname(app_path)
    @cache_path = Pathname(cache_path)
    @experiment_enabled = experiment_enabled
  end

  # Move cache directory contents into application directory
  def cache_to_app(dir: , overwrite:, rename: nil)
    copy(
      from_path: @cache_path.join(dir),
      to_path: @app_path.join(rename || dir),
      overwrite: overwrite,
      name: "cache_to_app"
    )
  end

  def app_to_cache(dir: , overwrite:, rename: nil)
    copy(
      from_path: @app_path.join(dir),
      to_path: @cache_path.join(rename || dir),
      overwrite: overwrite,
      name: "app_to_cache"
    )
  end

  # removes the the specified path from the cache
  # @param [String] relative path from thecache_path
  def clear(path)
    target = @cache_path.join(path)
    target.exist? && target.rmtree
  end

  # check if the cache content exists
  # @param [String] relative path of the cache contents
  # @param [Boolean] true if the path exists in the cache and false if otherwise
  def exists?(path)
    @cache_path.join(path).exist?
  end

  # copy cache contents
  # @param [String] source directory
  # @param [String] destination directory
  private def copy(from_path:, to_path:, overwrite: , name: )
    if @experiment_enabled
      diff = LanguagePack::Helpers::FsExtra::CompareCopy.new(
        from_path: from_path,
        to_path: to_path,
        report: @report,
        stack: @stack,
        reference_klass: LanguagePack::Helpers::FsExtra::ShellCopy,
        test_klass: LanguagePack::Helpers::FsExtra::Copy
      ).call
      @report.capture(
        "fs_extra_diff_different" => diff.different?,
      )

      if diff.different?
        # Abort on first failed experiment
        @experiment_enabled = false
        @report.capture(
          "fs_extra_diff_summary" => diff.summary,
        )
      end
    else
      copy_cp(from_path: from_path, to_path: to_path, overwrite: overwrite)
    end
  end

  private def copy_cp(from_path: , to_path:, overwrite: )
    return false unless from_path.exist?

    LanguagePack::Helpers::FsExtra::ShellCopy.new(
      from_path: from_path,
      to_path: to_path,
      overwrite: overwrite,
      stack: @stack
    ).call
  end

  private def copy_fs_extra(from_path:, to_path:, overwrite: )
    return false unless from_path.exist?

    LanguagePack::Helpers::FsExtra::Copy.new(
      from_path: from_path,
      to_path: to_path,
      overwrite: overwrite,
      stack: @stack
    ).call
  end
end
