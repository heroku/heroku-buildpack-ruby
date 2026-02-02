## Ruby applications with no specified bundler versions now receive Bundler 2.5.23

If your `Gemfile.lock` doesn’t include the `BUNDLED WITH` key, Heroku installs a [default bundler version](https://devcenter.heroku.com/articles/ruby-support-reference#default-bundler-version):

- Apps using [Classic Buildpacks](https://devcenter.heroku.com/articles/buildpacks#classic-buildpacks) was `2.3.25` now `2.5.23`
- Apps using [Cloud Native Buildpacks](https://devcenter.heroku.com/articles/buildpacks#heroku-cloud-native-buildpacks) stays `2.5.23`

>note
>Ruby's [standard version of bundler](https://stdgems.org/bundler/) takes precedence if it's greater than Heroku's installed version. When there is no `BUNDLED WITH` in the `Gemfile.lock`, then `bundle install` uses the highest version of Bundler available.

It is strongly recommended that you have both a `RUBY VERSION` and `BUNDLED WITH` version listed in your `Gemfile.lock`. If you do not have those values, you can generate them and commit them to git:

```
$ bundle update --ruby
$ git add Gemfile.lock
$ git commit -m "Update Gemfile.lock"
```

Applications without these values specified in the `Gemfile.lock` may break unexpectedly when the defaults change.
