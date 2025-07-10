# frozen_string_literal: true

module LanguagePack::Helpers
  module FsExtra
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

    # This class is used to copy a directory from one location to another.
    #
    # It should behave the same as `cp -a` when `overwrite` is true.
    # It should behave the same as `cp -a --update=none` when `overwrite` is false.
    class Copy
      def initialize(from_path:, to_path:, overwrite: )
        @from_path = Pathname(from_path)
        @to_path = Pathname(to_path)
        @overwrite = overwrite
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
          @from_path.children,
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
            parent = target.dirname
            parent.mkpath unless parent.exist?

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
