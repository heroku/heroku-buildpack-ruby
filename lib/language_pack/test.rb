require "language_pack"

module LanguagePack::Test
end

# Behavior changes for the test pack work by opening existing language_pack
# classes and over-writing their behavior to extend test functionality
require "language_pack/test/ruby"
require "language_pack/test/rails2"
require "language_pack/test/rails7"
