## Ruby buildpack now cleans unused binstubs before install

After a Ruby application's dependencies have been installed via `bundle install` the old dependencies are cleaned up by running `bundle clean`. Recently it was discovered that this does not clean up unused binstubs. To correct this problem the Ruby buildpack now manually cleans up generated binstubs in `vendor/bundler/bin`. Then when `bundle install` is executed, only currently used binstubs will be generated.

[Buildpack PR](https://github.com/heroku/heroku-buildpack-ruby/pull/914) and [Heroku Ruby support](https://devcenter.heroku.com/articles/ruby-support).