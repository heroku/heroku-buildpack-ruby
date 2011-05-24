#!/usr/bin/env ruby

$:.unshift File.expand_path("../../lib", __FILE__)
require "language_pack"

if pack = LanguagePack.detect(ARGV[0], ARGV[1])
  puts pack.release
end

