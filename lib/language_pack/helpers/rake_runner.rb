class LanguagePack::Helpers::RakeRunner
  include LanguagePack::ShellHelpers

  class CannotLoadRakefileError < StandardError
  end

  class RakeTask
    ALLOWED = [:pass, :fail, :no_load, :not_found]
    include LanguagePack::ShellHelpers

    attr_accessor :output, :time, :task, :status, :task_defined, :rakefile_can_load

    alias :rakefile_can_load? :rakefile_can_load
    alias :task_defined?      :task_defined
    alias :is_defined?        :task_defined

    def initialize(task, options = {})
      @task            = task
      @default_options = {user_env: true}.merge(options)
      @status          = :nil
      @output          = ""
    end

    def not_defined?
      !is_defined?
    end

    def success?
      status == :pass
    end

    def status?
      @status && @status != :nil
    end

    # Is set by RakeTask#invoke to one of the ALLOWED verbs
    def status
      raise "Status not set for #{self.inspect}" if @status == :nil
      raise "Not allowed status: #{@status} for #{self.inspect}" unless ALLOWED.include?(@status)
      @status
    end

    def invoke(options = {})
      options      = @default_options.merge(options)
      quiet_option = options.delete(:quiet)

      puts "Running: rake #{task}" unless quiet_option
      time = Benchmark.realtime do
        cmd = "rake #{task}"

        if quiet_option
          self.output = run("rake #{task}", options)
        else
          self.output = pipe("rake #{task}", options)
        end
      end
      self.time = time

      if $?.success?
        self.status = :pass
      else
        self.status = :fail
      end
      return self
    end
  end

  def initialize
    if !has_rake_installed?
      @rake_tasks    = ""
      @rakefile_can_load = false
    end
  end

  def cannot_load_rakefile?
    !rakefile_can_load?
  end

  def rakefile_can_load?
    @rakefile_can_load
  end

  def load_rake_tasks(options = {})
    @rake_tasks        ||= RakeTask.new("-P --trace").invoke(options.merge(quiet: true)).output
    @rakefile_can_load ||= $?.success?
    @rake_tasks
  end

  def load_rake_tasks!(options = {}, raise_on_fail = false)
    return if !has_rake_installed?

    out = load_rake_tasks(options)

    if cannot_load_rakefile?
      msg =  "Could not detect rake tasks\n"
      msg << "ensure you can run `$ bundle exec rake -P` against your app\n"
      msg << "and using the production group of your Gemfile.\n"
      msg << out
      raise CannotLoadRakefileError, msg if raise_on_fail
      puts msg
    end

    return self
  end

  def task_defined?(task)
    return false if cannot_load_rakefile?
    @task_available ||= Hash.new {|hash, key| hash[key] = @rake_tasks.match(/\s#{key}\s/) }
    @task_available[task]
  end

  def not_found?(task)
    !task_defined?(task)
  end

  def task(rake_task, options = {})
    t = RakeTask.new(rake_task, options)
    t.task_defined      = task_defined?(rake_task)
    t.rakefile_can_load = rakefile_can_load?
    t
  end

  def invoke(task, options = {})
    self.task(task, options).invoke
  end

  def has_rake_installed?
    @has_rake ||= has_rakefile?
  end

  private def has_rakefile?
    %W{ Rakefile rakefile  rakefile.rb Rakefile.rb}.detect {|file| File.exist?(file) }
  end
end
