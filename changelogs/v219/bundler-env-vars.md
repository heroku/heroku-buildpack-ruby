## Ruby applications now configure bundler with environment variables instead of flags

Previously the Ruby buildpack ran bundler installation with flags:

```
Running: bundle install --without development:test --path vendor/bundle --binstubs vendor/bundle/bin -j4 --deployment
[DEPRECATED] The `--deployment` flag is deprecated because it relies on being remembered across bundler invocations, which bundler will no longer do in future versions. Instead please use `bundle config set deployment 'true'`, and stop using this flag
[DEPRECATED] The `--path` flag is deprecated because it relies on being remembered across bundler invocations, which bundler will no longer do in future versions. Instead please use `bundle config set path 'vendor/bundle'`, and stop using this flag
[DEPRECATED] The `--without` flag is deprecated because it relies on being remembered across bundler invocations, which bundler will no longer do in future versions. Instead please use `bundle config set without 'development:test'`, and stop using this flag
[DEPRECATED] The --binstubs option will be removed in favor of `bundle binstubs`
```

In order to remove deprecations from Bundler 2.x, Ruby applications now run bundler installation with environment variables instead:

```
Running: BUNDLE_WITHOUT=development:test BUNDLE_PATH=vendor/bundle BUNDLE_BIN=vendor/bundle/bin BUNDLE_DEPLOYMENT=1 bundle install -j4
```

This behavior is documented in the [Heroku Ruby Support page](https://devcenter.heroku.com/articles/ruby-support).

