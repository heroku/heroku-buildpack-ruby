# frozen_string_literal: true

module LanguagePack::Helpers
  module FsExtra
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
