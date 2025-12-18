require 'rspec/core'
require 'hatchet'
require 'fileutils'
require 'stringio'
require 'hatchet'
require 'rspec/retry'
require 'language_pack'
require 'language_pack/shell_helpers'

ENV["HATCHET_BUILDPACK_BASE"] ||= "https://github.com/heroku/heroku-buildpack-ruby"

ENV['RACK_ENV'] = 'test'

DEFAULT_STACK = 'heroku-24'

def hatchet_path(path = "")
  Pathname(__FILE__).join("../../repos").expand_path.join(path)
end

RSpec.configure do |config|
  config.alias_example_to :fit, focused: true
  config.full_backtrace      = true
  config.verbose_retry       = true # show retry status in spec process
  config.example_status_persistence_file_path = 'spec/examples.txt'

  config.expect_with :rspec do |c|
    c.max_formatted_output_length = Float::INFINITY
    c.syntax = :expect
  end
  config.mock_with :nothing
  config.include LanguagePack::ShellHelpers
end

def successful_body(app, options = {})
  retry_limit = options[:retry_limit] || 50
  url = "http://#{app.name}.herokuapp.com"
  Excon.get(url, :idempotent => true, :expects => 200, :retry_limit => retry_limit).body
end

def create_file_with_size_in(size, dir)
  name = File.join(dir, SecureRandom.hex(16))
  File.open(name, 'w') {|f| f.print([ 1 ].pack("C") * size) }
  Pathname.new name
end

def buildpack_path
  File.expand_path(File.join("../.."), __FILE__)
end

def fixture_path(path)
  Pathname.new(__FILE__).join("../fixtures").expand_path.join(path)
end

def set_lts_ruby_version
  set_ruby_version(version: "3.3.6")
end

def set_ruby_version(version: )
  # Last ruby declaration in the gemfile wins
  Pathname("Gemfile").write("\nruby '#{version}'", mode: "a")

  # Update the Gemfile.lock to match
  contents = Pathname("Gemfile.lock").read.concat(<<~EOF)

    RUBY VERSION
       ruby #{version}p170
  EOF
  Pathname("Gemfile.lock").write(contents)
end

def set_bundler_version(version: )
  gemfile_lock = Pathname("Gemfile.lock").read

  if version == :default
    version = ""
  else
    version = "BUNDLED WITH\n   #{version}"
  end
  gemfile_lock.gsub!(/^BUNDLED WITH$(\r?\n)   (?<major>\d+)\.(?<minor>\d+)\.\d+/m, version)
  gemfile_lock << "\n#{version}" unless gemfile_lock.match?(/^BUNDLED WITH/)

  Pathname("Gemfile.lock").write(gemfile_lock)
end

def rails_lts_config
  { 'BUNDLE_GEMS__RAILSLTS__COM' => ENV["RAILS_LTS_CREDS"] }
end

def rails_lts_stack
  "heroku-22"
end

def hatchet_path(path = "")
  Pathname.new(__FILE__).join("../../repos").expand_path.join(path)
end

def dyno_status(app, ps_name = "web")
  app
    .api_rate_limit.call
    .dyno
    .list(app.name)
    .detect {|x| x["type"] == ps_name }
end

def wait_for_dyno_boot(app, ps_name = "web", sleep_val = 1)
  while ["starting", "restarting"].include?(dyno_status(app, ps_name)["state"])
    sleep sleep_val
  end
  dyno_status(app, ps_name)
end

def web_boot_status(app)
  wait_for_dyno_boot(app)["state"]
end

def root_dir
  Pathname(__dir__).join("..")
end

# Helper class for capturing and comparing environment variables in test output
# Used by both deploy tests and CI tests
class EnvDiff
  attr_reader :added, :modified, :path_before, :path_after, :env_hash

  def initialize(output, build_dir_pattern: /BUILD_DIR: (.+)/)
    if build_dir_pattern
      build_dir = output.match(build_dir_pattern)&.[](1)&.strip
      if build_dir
        output = output.gsub(build_dir, '<build dir>')
      else
        raise "build_dir_pattern #{build_dir_pattern.inspect} not found in output:\n#{output}"
      end
    end

    env_sections = extract_env_sections(output)

    if env_sections.size == 1
      # Single section mode (e.g., CI tests)
      @env_hash = env_sections[0]
    elsif env_sections.size == 2
      # Diff mode (before/after comparison)
      before_hash = env_sections[0]
      after_hash = env_sections[1]

      @path_before = before_hash["PATH"]
      @path_after = after_hash["PATH"]

      non_path_before = before_hash.except("PATH")
      non_path_after = after_hash.except("PATH")

      @added = (non_path_after.keys - non_path_before.keys).sort.map { |k| "#{k}=#{non_path_after[k]}" }
      @env_hash = after_hash
    elsif env_sections.size > 2
      raise "Too many print markers in output found:\n#{output}"
    else
      raise "Did not find any print markers in output:\n#{output}"
    end
  end

  private def extract_env_sections(output, start_marker: "## PRINTING ENV ##", end_marker: "## PRINTING ENV DONE ##")
    sections = []
    in_section = false
    current_env = {}

    output.each_line do |line|
      clean = line.gsub(/^\s*remote:\s*/, '').strip
      case clean
      when start_marker
        in_section = true
        current_env = {}
      when end_marker
        sections << current_env
        in_section = false
      else
        if in_section && clean.include?('=')
          key, value = clean.split('=', 2)
          current_env[key] = value
        end
      end
    end
    sections
  end
end

private def extract_remote_lines(output, start_marker: , end_marker: )
  lines = []
  in_section = false

  output.each_line do |line|
    clean = line.gsub(/^\s*remote:\s*/, '').strip
    case clean
    when start_marker
      in_section = true
    when end_marker
      in_section = false
    else
      if in_section
        lines << clean
      end
    end
  end
  lines
end
