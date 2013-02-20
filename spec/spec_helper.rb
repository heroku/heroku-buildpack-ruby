require 'shell'
require "bundler"
Bundler.require :default, :test
require "language_pack"
require "language_pack/blobstore_client"

def in_app_dir(&block)
  Dir.chdir app_dir, &block
end
