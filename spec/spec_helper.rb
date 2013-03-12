require "bundler"
Bundler.require :default, :test
ENV["BUILDPACK_CACHE"] = "/var/vcap/packages/buildpack_cache"
require "language_pack"
