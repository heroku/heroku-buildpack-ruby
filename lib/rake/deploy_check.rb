# A class for checking if a local copy of a repo can be tagged for a deploy
#
# Example:
#
#   deploy = DeployCheck.new(github: "heroku/heroku-buildpack-ruby")
#   deploy.check! # Checks that current main branch matches what's on github
#
# It also can pull tag versions and determine the next sequential version automatically:
#
#   deploy.next_version # => "v999" # Assuming the last version was v998
#
# It can determine status of tags
#
#   deploy.push_tags? #=> false
#
class DeployCheck
  attr_reader :github_url

  def initialize(github: , next_version: ENV["RELEASE_VERSION"])
    @github = github
    @github_url = "https://github.com/#{github}"
    @next_version = next_version
    @remote_tag_array = nil
  end

  def check!
    check_version!
    check_unstaged!
    check_branch!
    check_changelog!
    check_sync!
  end

  def push_tag?
    return true if !tag_exists_on_remote?
    return false if remote_tag_matches?

    # Tag exists, but is not the same commit, raise an error
    raise <<~EOM
      The tag you're pushing (#{next_version}) to #{@github} already exists and does not have the same SHA.
      You must resolve this manually.
    EOM
  end

  # Returns tuthy value if the remote contains the next version already
  def tag_exists_on_remote?
    remote_tag_array.include?(next_version)
  end

  # Returns a truthy value if the remote tag SHA matches the current local sha
  def remote_tag_matches?(remote_sha: remote_commit_sha(next_version), local_sha: local_commit)
    remote_sha == local_sha
  end

  # Raises an error if there are unstaged modifications
  def check_unstaged!
    run!("git diff --quiet HEAD") do
      raise "Must have all changes committed. There are unstaged commits locally"
    end
  end

  # Raises an error if not on the designated branch
  def check_branch!(name = "main")
    out = run("git rev-parse --abbrev-ref HEAD")
    raise "Must be on main branch. Branch: #{out}" unless out == name
  end

  # Raises an error if the changelog does not have an entry with the designated version
  def check_changelog!
    if !File.read("CHANGELOG.md").include?("## #{next_version}")
      raise "Expected CHANGELOG.md to include #{next_version} but it did not"
    end
  end

  # Raises an error if the local sha does not match the remote sha
  def check_sync!(local_sha: local_commit_sha, remote_sha: remote_commit_sha)
    return if remote_sha == local_sha

    raise <<~EOM
      Must be in-sync with #{@github}. Local comit: #{local_sha.inspect} #{@github}: #{remote_sha.inspect}
      "Make sure that you've pulled: `git pull --rebase #{@github_url} main`
    EOM
  end

  def check_version!
    version = next_version

    raise "Must look like a version: #{version}. Must start with `v` and include only digits" unless version.match?(/^v\d+$/)
  end

  def local_commit_sha
    run!("git rev-parse HEAD")
  end

  def remote_commit_sha(branch_or_tag = "main")
    run!("git ls-remote #{@github_url} #{branch_or_tag}").split("\t").first
  end

  def run(cmd)
    `#{cmd}`.strip
  end

  def next_version
    @next_version || "v#{next_version_number}"
  end

  def remote_tag_array
    @remote_tag_array ||= begin
      cmd = String.new("")
      cmd << "git ls-remote --tags #{@github_url}"
      cmd << "| awk '{print $2}' | cut -d '/' -f 3 | cut -d '^' -f 1"
      run!(cmd).each_line.map(&:strip).select {|line| line.strip.match?(/^v\d+$/) } # https://rubular.com/r/8eFB9r8nOVrM7H
    end
  end

  private def next_version_number
   integer_tag_array = remote_tag_array.map {|line| line.sub(/^v/, '').to_i }.sort # Ascending order
   integer_tag_array.last.next
  end

  def run!(cmd)
    out = run(cmd)
    return out if $?.success?

    if block_given?
      yield out, $?
    else
      raise "Command #{cmd} expected to return successfully did not: #{out}"
    end
  end
end
