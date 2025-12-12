# Queries S3 in the background to determine
# what versions are supported so they can be recommended
# to the user
#
# Example:
#
#   ruby_version = LanguagePack::RubyVersion.from_gemfile_lock(ruby: gemfile_lock.ruby)
#   outdated = LanguagePack::Helpers::OutdatedRubyVersion.new(
#     current_ruby_version: ruby_version,
#     fetcher: LanguagePack::Fetcher.new(LanguagePack::Base::VENDOR_URL, stack: "heroku-22")
#     fetcher: LanguagePack::Fetcher.new(LanguagePack::Base::VENDOR_URL, stack: "heroku-22", arch: "amd64")
#   )
#
#   outdated.call
#   puts outdated.suggested_ruby_minor_version
#   #=> "ruby-2.2.10"
class LanguagePack::Helpers::OutdatedRubyVersion
  DEFAULT_RANGE = 1..5
  attr_reader :current_ruby_version

  def initialize(current_ruby_version: , fetcher:)
    @current_ruby_version = current_ruby_version
    @fetcher      = fetcher
    @already_joined = false

    @minor_versions = []
    @eol_versions = []

    @minor_version_threads = []
    @eol_version_threads = []

    @suggested_eol_version = nil
    @suggested_minor_version = nil
  end

  def can_check?
    return false if current_ruby_version.jruby?

    true
  end

  # Enqueues checks in the background
  def call
    return self unless can_check?
    raise "Cannot `call()` twice" unless @minor_version_threads.empty?

    check_minor_versions
    check_eol_versions_major
    check_eol_versions_minor
    self
  end

  def join
    return unless can_check?
    return true if @already_joined
    raise "Must initalize threads with `call()` before joining" if @minor_version_threads.empty?

    @eol_versions = @eol_version_threads.map(&:value).compact
    @minor_versions = @minor_version_threads.map(&:value).compact
    @minor_versions << current_ruby_version.ruby_version


    @suggested_minor_version = @minor_versions
      .map { |v| v.sub('ruby-', '') }
      .sort_by { |v| Gem::Version.new(v) }
      .last

    @suggested_eol_version = @eol_versions
      .map { |v| v.sub('ruby-', '') }
      .sort_by { |v| Gem::Version.new(v) }
      .last(3)
      .first

    @already_joined = true
  end

  def suggested_ruby_minor_version
    join
    @suggested_minor_version
  end

  def latest_minor_version?
    join
    @suggested_minor_version == current_ruby_version.ruby_version
  end

  def eol?
    join

    return @eol_versions.length > 3
  end

  # Account for preview releases
  def maybe_eol?
    join

    return @eol_versions.length > 2
  end

  def suggest_ruby_eol_version
    return false unless maybe_eol?
    @suggested_eol_version
      .sub(/0$/, 'x')
  end

  # Checks for a range of "tiny" versions in parallel
  #
  # For example if 2.5.0 is given it will check for the existance of
  # - 2.5.1
  # - 2.5.2
  # - 2.5.3
  # - 2.5.4
  # - 2.5.5
  #
  # If the last elment in the series exists, it will continue to
  # search by enqueuing additional numbers until the final
  # value in the series is found
  private def check_minor_versions(range: DEFAULT_RANGE, base_version: current_ruby_version, &block)
    range.each do |i|
      @minor_version_threads << Thread.new do
        version = base_version.next_logical_version(i)
        next if !@fetcher.exists?("#{version}.tgz")

        if i == range.last
          check_minor_versions(
            range: Range.new(i+1, i+i),
            base_version: base_version
          )
        end

        version
      end
    end
  end

  # Checks to see if 3 minor versions exist above current version
  #
  # for example 2.4.0 would check for existance of:
  #   - 2.5.0
  #   - 2.6.0
  #   - 2.7.0
  #   - 2.8.0
  private def check_eol_versions_minor(range: DEFAULT_RANGE, base_version: current_ruby_version)
    range.each do |i|
      @eol_version_threads << Thread.new do
        version = base_version.next_minor_version(i)

        next if !@fetcher.exists?("#{version}.tgz")

        if i == range.last
          check_eol_versions_minor(
            range: Range.new(i+1, i+i),
            base_version: base_version
          )
        end

        version
      end
    end
  end

  # Checks to see if one major version exists above current version
  # if it does, then it will check for minor versions of that version
  #
  # For checking 2.5. it would check for the existance of 3.0.0
  #
  # If 3.0.0 exists then it will check for:
  #   - 3.1.0
  #   - 3.2.0
  #   - 3.3.0
  private def check_eol_versions_major
    @eol_version_threads << Thread.new do
      version = current_ruby_version.next_major_version(1)

      next if !@fetcher.exists?("#{version}.tgz")

      check_eol_versions_minor(
        base_version: LanguagePack::RubyVersion.default(last_version: version)
      )

      version
    end
  end
end
