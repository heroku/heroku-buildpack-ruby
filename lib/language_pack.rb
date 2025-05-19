require "pathname"
require 'benchmark'

require 'language_pack/shell_helpers'

# General Language Pack module
module LanguagePack
  module Helpers
  end

  # detects which language pack to use
  def self.detect(app_path:, cache_path:)
    if !File.exist?("Gemfile.lock")
      raise BuildpackError.new("Gemfile.lock required. Please check it in.")
    end

    pack = [ Rails8, Rails7, Rails6, Rails5, Rails42, Rails41, Rails4, Rails3, Rails2, Rack, Ruby ].detect do |klass|
      klass.use?
    end

    return pack ? pack.new(app_path: app_path, cache_path: cache_path) : nil
  end
end

$:.unshift File.expand_path("../../vendor", __FILE__)
$:.unshift File.expand_path("..", __FILE__)

require 'heroku_build_report'

require "language_pack/helpers/plugin_installer"
require "language_pack/helpers/stale_file_cleaner"
require "language_pack/helpers/rake_runner"
require "language_pack/helpers/rails_runner"
require "language_pack/helpers/bundler_wrapper"
require "language_pack/helpers/outdated_ruby_version"
require "language_pack/helpers/download_presence"
require "language_pack/installers/heroku_ruby_installer"

require "language_pack/ruby"
require "language_pack/rack"
require "language_pack/rails2"
require "language_pack/rails3"
require "language_pack/rails4"
require "language_pack/rails41"
require "language_pack/rails42"
require "language_pack/rails5"
require "language_pack/rails6"
require "language_pack/rails7"
require "language_pack/rails8"
