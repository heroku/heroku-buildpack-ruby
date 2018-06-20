require "shellwords"

class BuildpackError < StandardError
end

class NoShellEscape < String
  def shellescape
    self
  end
end

module LanguagePack
  module ShellHelpers
    @@user_env_hash = {}
    @@warnings      = []
    @@deprecations  = []

    def warnings
      @@warnings
    end

    def deprecations
      @@deprecations
    end

    def mcount(key, value = 1)
      private_log("count", key => value)
    end

    def mmeasure(key, value)
      private_log("measure", key => value)
    end

    def munique(key, value)
      private_log("unique", key => value)
    end

    def self.user_env_hash
      @@user_env_hash
    end

    def user_env_hash
      @@user_env_hash
    end

    def env(var)
      ENV[var] || user_env_hash[var]
    end

    def self.blacklist?(key)
      %w(PATH GEM_PATH GEM_HOME GIT_DIR JRUBY_OPTS JAVA_OPTS JAVA_TOOL_OPTIONS).include?(key)
    end

    def self.initialize_env(path)
      env_dir = Pathname.new("#{path}")
      if env_dir.exist? && env_dir.directory?
        env_dir.each_child do |file|
          key   = file.basename.to_s
          value = file.read.strip
          user_env_hash[key] = value unless blacklist?(key)
        end
      end
    end

    # run a shell command (deferring to #run), and raise an error if it fails
    # @param [String] command to be run
    # @return [String] result of #run
    # @option options [Error] :error_class Class of error to raise, defaults to Standard Error
    # @option options [Integer] :max_attempts Number of times to attempt command before raising
    def run!(command, options = {})
      max_attempts = options[:max_attempts] || 1
      error_class = options[:error_class] || StandardError
      max_attempts.times do |attempt_number|
        result = run(command, options)
        if $?.success?
          return result
        end
        if attempt_number == max_attempts - 1
          raise error_class, "Command: '#{command}' failed unexpectedly:\n#{result}"
        else
          puts "Command: '#{command}' failed on attempt #{attempt_number + 1} of #{max_attempts}."
        end
      end
    end

    # doesn't do any special piping. stderr won't be redirected.
    # @param [String] command to be run
    # @return [String] output of stdout
    def run_no_pipe(command, options = {})
      run(command, options.merge({:out => ""}))
    end

    # run a shell command and pipe stderr to stdout
    # @param [String] command
    # @option options [String] :out the IO redirect of the command
    # @option options [Hash] :env explicit environment to run command in
    # @option options [Boolean] :user_env whether or not a user's environment variables will be loaded
    def run(command, options = {})
      %x{ #{command_options_to_string(command, options)} }
    end

    # run a shell command and pipe stderr to /dev/null
    # @param [String] command to be run
    # @return [String] output of stdout
    def run_stdout(command, options = {})
      options[:out] ||= '2>/dev/null'
      run(command, options)
    end

    def command_options_to_string(command, options)
      options[:env] ||= {}
      options[:out] ||= "2>&1"
      options[:env] = user_env_hash.merge(options[:env]) if options[:user_env]
      env = options[:env].map {|key, value| "#{key.shellescape}=#{value.shellescape}" }.join(" ")
      "/usr/bin/env #{env} bash -c #{command.shellescape} #{options[:out]} "
    end

    # run a shell command and stream the output
    # @param [String] command to be run
    def pipe(command, options = {})
      output = options[:buffer] || ""
      silent = options[:silent]
      IO.popen(command_options_to_string(command, options)) do |io|
        until io.eof?
          buffer = io.gets
          output << buffer
          puts buffer unless silent
        end
      end

      output
    end

    # display a topic message
    # (denoted by ----->)
    # @param [String] topic message to be displayed
    def topic(message)
      Kernel.puts "-----> #{message}"
      $stdout.flush
    end

    # display a message in line
    # (indented by 6 spaces)
    # @param [String] message to be displayed
    def puts(message)
      message.each_line do |line|
        if line.end_with?("\n".freeze)
          print "       #{line}"
        else
          print "       #{line}\n"
        end
      end

      $stdout.flush
    rescue ArgumentError => e
      error_message = e.message
      raise e if error_message !~ /invalid byte sequence/

      mcount "fail.invalid_utf8"
      error_message << "\n       Invalid string: #{message}"
      raise e, error_message
    end

    def warn(message, options = {})
      if options.key?(:inline) ? options[:inline] : false
        Kernel.puts "###### WARNING:"
        puts message
        Kernel.puts ""
      end
      warnings << message
    end

    def error(message)
      raise BuildpackError, message
    end

    def deprecate(message)
      deprecations << message
    end

    def noshellescape(string)
      NoShellEscape.new(string)
    end

    private
      def private_log(name, key_value_hash)
        File.open(ENV["BUILDPACK_LOG_FILE"] || "/dev/null", "a+") do |f|
          key_value_hash.each do |key, value|
            metric = String.new("#{name}#")
            metric << "#{ENV["BPLOG_PREFIX"]}"
            metric << "." unless metric.end_with?('.')
            metric << "#{key}=#{value}"
            f.puts metric
          end
        end
      end
  end
end
