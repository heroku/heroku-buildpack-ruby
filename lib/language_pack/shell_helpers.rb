require "shellwords"

class NoShellEscape < String
  def shellescape
    self
  end
end

module LanguagePack
  module ShellHelpers
    @@user_env_hash = {}

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
      %w(PATH GEM_PATH GEM_HOME GIT_DIR).include?(key)
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

    # display error message and stop the build process
    # @param [String] error message
    def error(message)
      Kernel.puts " !"
      message.split("\n").each do |line|
        Kernel.puts " !     #{line.strip}"
      end
      Kernel.puts " !"
      log "exit", :error => message if respond_to?(:log)
      exit 1
    end

    def run!(command, options = {})
      result = run(command, options)
      error("Command: '#{command}' failed unexpectedly:\n#{result}") unless $?.success?
      return result
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
      output = ""
      IO.popen(command_options_to_string(command, options)) do |io|
        until io.eof?
          buffer = io.gets
          output << buffer
          puts buffer
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
      message.split("\n").each do |line|
        super "       #{line.strip}"
      end
      $stdout.flush
    end

    def warn(message, options = {})
      if options.key?(:inline) ? options[:inline] : false
        topic "Warning:"
        puts message
      end
      @warnings ||= []
      @warnings << message
    end

    def deprecate(message)
      @deprecations ||= []
      @deprecations << message
    end

    def noshellescape(string)
      NoShellEscape.new(string)
    end
  end
end
