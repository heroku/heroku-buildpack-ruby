## Bundler version 4.0.0.beta2 is now available for Ruby Applications

The [Ruby Buildpack](https://devcenter.heroku.com/articles/ruby-support#libraries) installs a version of bundler based on the major and minor version listed in the `Gemfile.lock` under the `BUNDLED WITH` key:

- `BUNDLED WITH` 4.0.x will receive bundler `4.0.0.beta2`

It is strongly recommended that you have both a `RUBY VERSION` and `BUNDLED WITH` version listed in your `Gemfile.lock`. If you do not have those values, you can generate them and commit them to git:

```
$ bundle update --ruby
$ git add Gemfile.lock
$ git commit -m "Update Gemfile.lock"
```

Applications without these values specified in the `Gemfile.lock` may break unexpectedly when the defaults change.

> Note
> This version of Bundler is not suitable for production applications.
> However, it can be used to test that your application is ready for
> the official release of Bundler 4.0.
