#!/usr/bin/env ruby

# sync output
$stdout.sync = true

$:.unshift File.expand_path("../../lib", __FILE__)
require "language_pack"
require "language_pack/shell_helpers"

begin
  LanguagePack::Instrument.trace 'compile', 'app.compile' do
    LanguagePack::ShellHelpers.initialize_env(ARGV[2])
    if pack = LanguagePack.detect(ARGV[0], ARGV[1])
      pack.topic("Compiling #{pack.name}")
      pack.log("compile") do
        pack.compile
      end
    end
  end
rescue Exception => e
  Kernel.puts " !"
  e.message.split("\n").each do |line|
    Kernel.puts " !     #{line.strip}"
  end
  Kernel.puts " !"
  if e.is_a?(BuildpackError)
    exit 1
  else
    raise e
  end
end
