require 'zip'

module CloudFoundry
  module BuildpackPackager
    DEPENDENCIES = [
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/node-0.4.7.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/libyaml-0.1.6.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/bundler-1.5.2.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby_versions.yml',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-2.1.1.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-2.1.0.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-2.0.0.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.9.3.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.9.2.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.8.7.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-build-1.8.7.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.8.7-jruby-1.7.1.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.9.3-jruby-1.7.1.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.8.7-jruby-1.7.2.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.9.3-jruby-1.7.2.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.8.7-jruby-1.7.3.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.9.3-jruby-1.7.3.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.8.7-jruby-1.7.4.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.9.3-jruby-1.7.4.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.8.7-jruby-1.7.5.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.9.3-jruby-1.7.5.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-2.0.0-jruby-1.7.5.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.8.7-jruby-1.7.6.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.9.3-jruby-1.7.6.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-2.0.0-jruby-1.7.6.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.8.7-jruby-1.7.8.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.9.3-jruby-1.7.8.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-2.0.0-jruby-1.7.8.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.8.7-jruby-1.7.9.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.9.3-jruby-1.7.9.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-2.0.0-jruby-1.7.9.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.8.7-jruby-1.7.10.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.9.3-jruby-1.7.10.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-2.0.0-jruby-1.7.10.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.8.7-jruby-1.7.11.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-1.9.3-jruby-1.7.11.tgz',
        'https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/ruby-2.0.0-jruby-1.7.11.tgz',
        'http://heroku-jdk.s3.amazonaws.com/openjdk1.7.0_25.tar.gz',
        'http://heroku-jdk.s3.amazonaws.com/openjdk1.7.0_45.tar.gz',
        'http://heroku-jdk.s3.amazonaws.com/openjdk7-latest.tar.gz'
    ]

    EXCLUDE_FROM_BUILDPACK = [
        /\.git/,
        /repos/
    ]

    class << self
      def package
        Dir.mktmpdir do |temp_dir|
          copy_buildpack_contents(temp_dir)
          download_dependencies(temp_dir) unless ENV['ONLINE']
          compress_buildpack(temp_dir)
        end
      end

      private

      def copy_buildpack_contents(target_path)
        run_cmd "cp -r * #{target_path}"
      end

      def download_dependencies(target_path)
        dependency_path = File.join(target_path, 'dependencies')

        run_cmd "mkdir -p #{dependency_path}"

        DEPENDENCIES.each do |uri|
          run_cmd "cd #{dependency_path}; curl #{uri} -O"
        end
      end

      def in_pack?(file)
        !EXCLUDE_FROM_BUILDPACK.any? { |re| file =~ re }
      end

      def compress_buildpack(target_path)
        Zip::File.open('ruby_buildpack.zip', Zip::File::CREATE) do |zipfile|
          Dir[File.join(target_path, '**', '**')].each do |file|
            zipfile.add(file.sub(target_path + '/', ''), file) if (in_pack?(file))
          end
        end
      end

      def run_cmd(cmd)
        puts "$ #{cmd}"
        `#{cmd}`
      end
    end
  end
end
