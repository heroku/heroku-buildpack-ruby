## Bundler versions 2.4.22 and 2.5.6 are now available for Ruby Applications

The [Ruby Buildpack](https://devcenter.heroku.com/articles/ruby-support#libraries) now installs a version of bundler based on the major and minor version listed in the `Gemfile.lock` under the `BUNDLED WITH` key. Previously, it only used the major version. Now, this logic will be used:

- `BUNDLED WITH` 1.x will receive bundler `1.17.3`
- `BUNDLED WITH` 2.0.x to 2.3.x will receive bundler `2.3.25`
- `BUNDLED WITH` 2.4.x will receive bundler `2.4.22`
- `BUNDLED WITH` 2.5.x and above will receive bundler `2.5.6`

It is strongly recommended that you have both a `RUBY VERSION` and `BUNDLED WITH` version listed in your `Gemfile.lock`. If you do not have those values, you can generate them and commit them to git:

```
$ bundle update --ruby
$ git add Gemfile.lock
$ git commit -m "Update Gemfile.lock"
```

Applications without these values specified in the `Gemfile.lock` may break unexpectedly when the defaults change.
