require 'fileutils'
require 'pathname'

$:.unshift File.join(__dir__, "..") # put lib on the path
require "language_pack/installers/heroku_ruby_installer"
require "language_pack/ruby_version"
require "language_pack/version"

# This class takes a target directory (such as the buildpack)
# and tars it up so it's in a form ready to be run
#
# In addition to TAR logic it also vendors ruby versions so
# they don't need to be pulled at runtime
class Tarballer
  STACKS = %W{cedar-14 heroku-16 heroku-18}

  def initialize(name: , directory: , io: STDOUT)
    @name = name
    @source_directory = Pathname.new(directory)
    @version = LanguagePack::Base::BUILDPACK_VERSION
    @dest_directory = @source_directory.join("buildpacks")
    @dest_directory.mkpath
    @io = io
  end

  def call(stacks: STACKS)
    Dir.mktmpdir do |tmpdir_base|
      tmp_dir = Pathname.new(tmpdir_base).join(@name)
      run! "cp -r #{@source_directory} #{tmp_dir}"

      Dir.chdir(tmp_dir) do |buildpack_dir|
        stacks.each do |stack|
          installer    = LanguagePack::Installers::HerokuRubyInstaller.new(stack)
          ruby_version = LanguagePack::RubyVersion.new("ruby-#{LanguagePack::RubyVersion::DEFAULT_VERSION_NUMBER}")
          installer.fetch_unpack(ruby_version, "vendor/ruby/#{stack}")
        end
        run! "tar czf #{tmp_dir.join('.buildpack.tgz')} *"
      end

      tar_destination = @dest_directory.join("heroku-buildpack-ruby-#{@version}.tgz")
      @io.puts "Writing to #{tar_destination}"

      FileUtils.cp(tmp_dir.join('.buildpack.tgz'), tar_destination)
    end
  end

  private def run!(cmd)
    out = `#{cmd}`
    raise "Command: #{cmd} was expected to succeed but it did not. Output: #{out}" unless $?.success?
    out
  end
end
