## Bundler version 2.6.9 and 2.7.2 are now available for Ruby Applications

The [Ruby Buildpack](https://devcenter.heroku.com/articles/ruby-support#libraries) installs a version of bundler based on the major and minor version listed in the `Gemfile.lock` under the `BUNDLED WITH` key:

- `BUNDLED WITH` 2.6.x will receive bundler `2.6.9`
- `BUNDLED WITH` 2.7.x will receive bundler `2.7.2`

It is strongly recommended that you have both a `RUBY VERSION` and `BUNDLED WITH` version listed in your `Gemfile.lock`. If you do not have those values, you can generate them and commit them to git:

```
$ bundle update --ruby
$ git add Gemfile.lock
$ git commit -m "Update Gemfile.lock"
```

Applications without these values specified in the `Gemfile.lock` may break unexpectedly when the defaults change.
