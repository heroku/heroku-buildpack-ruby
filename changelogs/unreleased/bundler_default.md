## Ruby applications with no specified bundler versions now receive Bundler 2.3.27

Previously applications with no `BUNDLED WITH` in their `Gemfile.lock` would receive bundler `2.3.25` for Classic buildpacks and `2.5.23` for Cloud Native Buildpacks (CNB). They will now both receive `2.3.27` as the new [default bundler version](https://devcenter.heroku.com/articles/ruby-support-reference#default-bundler-version).

> Note
> Ruby 2.6+ includes bundler as a default gem. The default gem version of bundler will be used unless it is less than `2.3.27`.

It is strongly recommended that you have both a `RUBY VERSION` and `BUNDLED WITH` version listed in your `Gemfile.lock`. If you do not have those values, you can generate them and commit them to git:

```
$ bundle update --ruby
$ git add Gemfile.lock
$ git commit -m "Update Gemfile.lock"
```

Applications without these values specified in the `Gemfile.lock` may break unexpectedly when the defaults change.
