# frozen_string_literal: true

# This class is used for running `rails runner` against
# apps, primarially for the intention of detecting configuration.
#
# The main benefit of this class is that multiple config
# queries can be grouped together so the application only
# has to be booted once. Calling `did_match` on a
# RailsConfig object will trigger the `rails runner` command
# to be executed.
#
# Example usage:
#
#    rails_config   = RailsRunner.new
#    local_storage  = rails_config.detect("active_storage.service")
#    assets_compile = rails_config.detect("assets.compile")
#
#    local_storage.success?             # => true
#    local_storage.did_match?("local")  # => false
#
#    assets_compile.success?            # => true
#    assets_compile.did_match?("false") # => true
#
class LanguagePack::Helpers::RailsRunner
  # This class is used to help pull configuration values
  # from a rails application. It takes in a configuration key
  # and a reference to the parent RailsRunner object which
  # allows it obtain the `rails runner` output and success
  # status of the operation.
  #
  # For example:
  #
  #    config = RailsConfig.new("active_storage.service", rails_runner)
  #    config.to_command # => "puts %Q{heroku.detecting.config.for.active_storage.service=Rails.application.config.try(:active_storage).try(:service)}; "
  #
  class RailsConfig
    def initialize(config, rails_runner, options={})
      @config       = config
      @rails_runner = rails_runner
      @debug        = options[:debug]

      @success      = nil
      @did_time_out = false
      @heroku_key   = "heroku.detecting.config.for.#{config}"

      @rails_config = String.new('#{')
      @rails_config << 'Rails.application.config'
      config.split('.').each do |part|
        @rails_config << ".try(:#{part})"
      end
      @rails_config << '}'
    end

    def success?
      @rails_runner.success? && @rails_runner.output =~ %r(#{@heroku_key})
    end

    def did_match?(val)
      @rails_runner.output =~ %r(#{@heroku_key}=#{val})
    end

    def to_command
      cmd = String.new('begin; ')
      cmd << 'puts %Q{'
      cmd << "#{@heroku_key}=#{@rails_config}"
      cmd << '}; '
      cmd << 'rescue => e; '
      cmd << 'puts e; puts e.backtrace; ' if @debug
      cmd << 'end;'
      cmd
    end
  end

  include LanguagePack::ShellHelpers

  def initialize(debug = env('HEROKU_DEBUG_RAILS_RUNNER'), timeout = 65)
    @command_array = []
    @output        = nil
    @success       = false
    @debug         = debug
    @timeout_val   = timeout # seconds
  end

  def detect(config_string)
    config = RailsConfig.new(config_string, self, debug: @debug)
    @command_array << config.to_command
    config
  end

  def output
    @output ||= call
  end

  def success?
    output && @success
  end

  def command
    %Q{rails runner "#{@command_array.join(' ')}"}
  end

  def timeout?
    @did_time_out
  end

  private
    def call
      topic("Detecting rails configuration")
      puts "$ #{command}" if @debug
      out = execute_command!
      puts out if @debug
      out
    end

    def execute_command!
      process = ProcessSpawn.new(command,
        user_env: true,
        timeout:  @timeout_val,
        file:     "./.heroku/ruby/config_detect/rails.txt"
      )

      @success      = process.success?
      @did_time_out = process.timeout?
      out           = process.output

      if timeout?
        message = String.new("Detecting rails configuration timeout\n")
        message << "set HEROKU_DEBUG_RAILS_RUNNER=1 to debug" unless @debug
        warn(message)
        mcount("warn.rails.runner.timeout")
      elsif !@success
        message = String.new("Detecting rails configuration failed\n")
        message << "set HEROKU_DEBUG_RAILS_RUNNER=1 to debug" unless @debug
        warn(message)
        mcount("warn.rails.runner.fail")
      end

      return out
    end
end

