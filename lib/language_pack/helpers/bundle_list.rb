require "language_pack/shell_helpers"

module LanguagePack::Helpers
  class BundleList
    class CmdError < BuildpackError
      def initialize(command:, output:)
        super(<<~EOF)
          Error detecting dependencies

          The Ruby buildpack requires information about your application’s dependencies to
          complete the build. Without this information, the Ruby buildpack cannot continue.

          Command failed: `#{command}`

          #{output}
        EOF
      end
    end

    # Runs `bundle list` and builds a BundleList object
    # from the output
    #
    # Announces the run, optionally streams results to the user.
    # This is useful for the case where bundler doesn't print
    # any version info.
    #
    # Example:
    #
    #    BundleList::Command.new(
    #      stream_to_user: stream_to_user
    #    ).call
    class HumanCommand
      include LanguagePack::ShellHelpers
      private attr_reader :stream_to_user, :io

      def initialize(stream_to_user:, io: self)
        @io = io
        @stream_to_user = stream_to_user
      end

      def call
        command = "bundle list"
        io.puts "Running: #{command}"

        output = if stream_to_user
          pipe(command, user_env: true, output_object: io)
        else
          run(command, user_env: true)
        end

        if $?.success?
          BundleList.new(
            output: output
          )
        else
          raise CmdError.new(output: output, command: command)
        end
      end
    end

    def initialize(output: )
      @raw = output
      @gems = {}
      @raw.scan(/\* (?<name>\S+) \((?<version>[a-zA-Z0-9\.]+)(?<git_sha> [a-zA-Z0-9]+)?\)/) do
        captures = Regexp.last_match.named_captures
        @gems[captures["name"]] = captures["version"]
      end
    end

    def has_gem?(name)
      @gems[name]
    end

    def length
      @gems.length
    end

    def gem_version(name)
      if version = @gems[name]
        Gem::Version.new(version)
      end
    end
  end
end
