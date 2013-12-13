#!/usr/bin/env ruby

# sync output
$stdout.sync = true

$:.unshift File.expand_path("../../lib", __FILE__)
require "language_pack"
require "language_pack/shell_helpers"

LanguagePack::Instrument.trace 'compile', 'app.compile' do
  if pack = LanguagePack.detect(ARGV[0], ARGV[1])
    LanguagePack::ShellHelpers.initialize_env(ARGV[2])
    pack.topic("Compiling #{pack.name}")
    pack.log("compile") do
      pack.compile
    end
  end
end
