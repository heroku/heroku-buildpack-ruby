# frozen_string_literal: true

require 'digest'

module LanguagePack::Helpers
  module FsExtra
    class CompareCopy
      def initialize(from_path:, to_path:, reference_klass: , test_klass: , name: , overwrite:, stack: ENV["STACK"])
        @name = name
        @stack = stack
        @from_path = Pathname(from_path)
        @to_path = Pathname(to_path)
        @reference_klass = reference_klass
        @test_klass = test_klass
        @overwrite = overwrite
      end

      def call
        Dir.mktmpdir do |dir|
          # Prepare fake operation
          fake_from_path = Pathname(dir).join("source")
          fake_to_path = Pathname(dir).join("destination")

          # Setup fake directories
          if @from_path.exist?
            @reference_klass.new(from_path: @from_path, to_path: fake_from_path, overwrite: true).call
          end
          if @to_path.exist?
            @reference_klass.new(from_path: @to_path, to_path: fake_to_path, overwrite: true).call
          end

          # Perform test operation
          @test_klass.new(from_path: fake_from_path, to_path: fake_to_path, overwrite: @overwrite).call

          # Perform reference operation
          @reference_klass.new(from_path: @from_path, to_path: @to_path, overwrite: @overwrite).call

          # Compare results
          RsyncDiff.new(
            from_path: @to_path,
            to_path: fake_to_path,
            notes: "Operation: #{@name}, Overwrite: #{@overwrite}"
          ).call
        end
      end
    end

    class RsyncDiff
      def initialize(from_path:, to_path:, notes: nil, io: $stderr)
        @io = io
        @from_path = Pathname(from_path)
        @to_path = Pathname(to_path)
        @notes = notes
      end

      def call
        from_path = Shellwords.escape(@from_path)
        to_path = Shellwords.escape(@to_path)

        options = Shellwords.join([
          #  -a, --archive               archive mode; equals -rlptgoD (no -H,-A,-X)
          #
          # That means it will
          #   - r  copy recursively
          #   - l  copy symlinks
          #   - p  preserve permissions
          #   - t  preserve times
          #   - g  preserve group
          #   - o  preserve owner
          #   - D  preserve device files
          "--archive",

          #  -n, --dry-run               perform a trial run with no changes made
          "--dry-run",

          #  -i, --itemize-changes       output a change-summary for all updates
          #
          # This allows us to see if the directories are different if the output is empty
          "--itemize-changes",

          #  -c, --checksum              skip based on checksum, not mod-time & size
          "--checksum",

          #  --delete                    delete extraneous files from dest dirs
          #
          # This allows us to detect extra files in the destination that don't exist in source
          "--delete",
        ])
        command = "rsync #{options} #{from_path}/ #{to_path}/ 2>&1"
        output = `#{command}`.strip
        exit_status = $?
        @io.puts "WARNING: Diagnostic rsync command failed `#{command}`:\n#{output}" unless exit_status.success?

        RsyncDiffSummary.new(
          notes: @notes,
          output: output,
          from_path: @from_path,
          to_path: @to_path,
          # See: https://download.samba.org/pub/rsync/rsync.1 (search "EXIT VALUES")
          # Note: exit code 0 means success, not necessarily that nothing would be transferred.
          # Always check rsync output to determine if directories differ.
          is_different: !output.strip.empty?,
        )
      end

      # Formats and displays the results of the rsync diff
      #
      # Expected targets include print debugging and logging to otel (like honeycomb)
      class RsyncDiffSummary
        def initialize(from_path:, to_path:, output: , is_different:, notes: nil)
          @from_path = from_path
          @to_path = to_path
          @output = output
          @is_different = is_different
          @notes = notes
        end

        def different?
          @is_different
        end

        def summary
          if different?
            max_lines = 10
            max_chars = 1024

            lines = @output.lines
            count = lines.length

            if count > max_lines
              selected_lines = lines.take(max_lines) + ["And more ...\n"]
            else
              selected_lines = lines
            end
            summary_text = selected_lines.join

            # Truncate if over character limit
            if summary_text.length > max_chars
              summary_text = summary_text[0...max_chars] + "... (truncated)"
            end

            [
              "Directories `#{@from_path}` and `#{@to_path}` differ (#{[max_lines, count].min}/#{count} lines):",
              @notes,
              summary_text
            ].join("\n")
          else
            ["Directories `#{@from_path}` and `#{@to_path}` are identical", @notes, @output].join("\n")
          end
        end
      end
    end

    class ShellCopy
      def initialize(from_path:, to_path:, overwrite: , stack: ENV["STACK"])
        @from_path = Pathname(from_path)
        @to_path = Pathname(to_path)
        @overwrite = overwrite
        @stack = stack
      end

      def options
        if @overwrite
          "-a"
        else
          case @stack
          when "heroku-22"
            "-a -n"
          else
            "-a --update=none"
          end
        end
      end

      def call
        return false unless @from_path.exist?

        @to_path.dirname.mkpath
        command = "cp #{options} #{@from_path}/. #{@to_path} 2>&1"
        system(command)
        raise "Command failed `#{command}`" unless $?.success?
      end
    end

    # This class is used to copy a directory from one location to another.
    #
    # It should behave the same as `cp -a` when `overwrite` is true.
    # It should behave the same as `cp -a --update=none` when `overwrite` is false.
    class Copy
      def initialize(from_path:, to_path:, overwrite: , stack: ENV["STACK"])
        @from_path = Pathname(from_path)
        @to_path = Pathname(to_path)
        @overwrite = overwrite
        # Same interface as ShellCopy
        _stack = stack
      end

      # When force is true, it should behaves the same as `cp -a`
      # When force is false, it should behave the same as `cp -a --update=none`
      def call
        if @overwrite
          copy_overwrite
        else
          copy_update
        end
      end

      private def copy_overwrite
        FileUtils.cp_r(
          # If to and from are both directories, like `source/` and `destination/` then
          # calling `cp_r` and passing in the directory will create a `destination/source/` directory which is not what we want.
          #
          # A workaround is to copy the children list into the destination directory.
          @to_path.exist? ? @from_path.children : @from_path,
          @to_path,
          # Preserve file times and permissions
          preserve: true,
          # Preserve symlinks
          dereference_root: false
        )
      end

      private def copy_update
        @from_path.glob("**/*") do |from_file|
          target = @to_path.join(from_file.relative_path_from(@from_path))

          if target.exist?
            # Preserve original file
          else
            target_parent = target.dirname

            if target_parent.exist?
              # No need to create parent directory
            else
              # Parent directory does not exist in target, we can recursively copy it
              #
              # That's okay here because we validate that the directory is empty, therefore
              # no files inside of it will be overwritten and we can bypass the update check.
              #
              # For all the other files in this directory, the above target.exist? check will return true
              from_file = from_file.parent
              target = target_parent
            end

            # Use FileUtils.copy_entry for all files to properly handle symlinks
            # This will preserve symlinks and handle directories correctly
            #
            # WARNING: FileUtils.copy_entry will overwrite existing files/directories in the destination.
            # The `if target.exist?` check above is essential to prevent overwriting when overwrite: false.
            FileUtils.copy_entry(
              from_file,
              target,
              # Preserve copied file times and permissions
              preserve: true,
              # Preserve symlinks
              dereference_root: false
            )
          end
        end
      end
    end
  end
end
