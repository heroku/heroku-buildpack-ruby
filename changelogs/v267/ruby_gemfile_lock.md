## Ruby applications without a `RUBY VERSION` in the Gemfile.lock may receive a default Ruby version

Previously, it was possible to specify a full version of Ruby in the `Gemfile` even if it was not present in the `Gemfile.lock`. The Ruby directive in the `Gemfile` was parsed by bundler and emitted via the command `bundle --platform ruby`. This behavior has changed with bundler `2.4+`, so only ruby versions listed in the `RUBY VERSION` key of the `Gemfile.lock` will be returned. If your application uses bundler 2.4+ and does not have a `RUBY VERSION` specified in the `Gemfile.lock`, it will receive a default version of Ruby.

It is strongly recommended that you have both a `RUBY VERSION` and `BUNDLED WITH` version listed in your `Gemfile.lock`. If you do not have those values, you can generate them and commit them to git:

```
$ bundle update --ruby
$ git add Gemfile.lock
$ git commit -m "Update Gemfile.lock"
```

Applications without these values specified in the `Gemfile.lock` may break unexpectedly when the defaults change.

If your app relies on specifying the ruby version in the `Gemfile` but not the `Gemfile.lock` and it is not yet using Bundler 2.4+, you may preserve this behavior by not upgrading the bundler version in your `Gemfile.lock`, however, this behavior is deprecated. It will be removed at a future date. It is recommended you lock your Ruby version now to avoid an unexpected breakage in the future.
