## Ruby applications with no specified bundler versions now receive Bundler 2.x

Previously applications with no `BUNDLED WITH` in their `Gemfile.lock` would receive bundler `1.x`. They will now receive the new [default bundler version](https://devcenter.heroku.com/articles/ruby-support-reference#default-bundler-version) `2.3.x`.

It is strongly recommended that you have both a `RUBY VERSION` and `BUNDLED WITH` version listed in your `Gemfile.lock`. If you do not have those values, you can generate them and commit them to git:

```
$ bundle update --ruby
$ git add Gemfile.lock
$ git commit -m "Update Gemfile.lock"
```

Applications without these values specified in the `Gemfile.lock` may break unexpectedly when the defaults change.
