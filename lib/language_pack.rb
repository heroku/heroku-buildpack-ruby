require "pathname"
require 'benchmark'

# General Language Pack module
module LanguagePack
  module Helpers
  end

  # detects which language pack to use
  # @param [Array] first argument is a String of the build directory
  # @return [LanguagePack] the {LanguagePack} detected
  def self.detect(*args)
    Instrument.instrument 'detect' do
      Dir.chdir(args.first)

      pack = [ NoLockfile, Rails4, Rails3, Rails2, Rack, Ruby ].detect do |klass|
        klass.use?
      end

      return pack ? pack.new(*args) : nil
    end
  end

end


$:.unshift File.expand_path("../../vendor", __FILE__)
$:.unshift File.expand_path("..", __FILE__)

require 'dotenv'
require 'language_pack/shell_helpers'
require 'language_pack/instrument'
require "language_pack/helpers/plugin_installer"
require "language_pack/helpers/stale_file_cleaner"
require "language_pack/helpers/rake_runner"
require "language_pack/helpers/default_cache"

require "language_pack/ruby"
require "language_pack/rack"
require "language_pack/rails2"
require "language_pack/rails3"
require "language_pack/disable_deploys"
require "language_pack/rails4"
require "language_pack/no_lockfile"
require "language_pack/helpers/bundler_wrapper"
