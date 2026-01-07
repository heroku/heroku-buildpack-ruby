## Ruby applications now receive exact bundler version

The exact bundler version from the `Gemfile.lock` is now installed with no conversion.

If your application fails after this change, you can manually adjust your `BUNDLED WITH` value in the `Gemfile.lock` to match the previously used exact version:

- `BUNDLED WITH 1.x.` installs `bundler 1.17.3`
- `BUNDLED WITH 2.0.x to 2.3.x` installs `bundler 2.3.25`
- `BUNDLED WITH 2.4.x` installs `bundler 2.4.22`
- `BUNDLED WITH 2.5.x` installs `bundler 2.5.23`
- `BUNDLED WITH 2.6.x` installs `bundler 2.6.9`
- `BUNDLED WITH 2.7.x` installs `bundler 2.7.2`
- `BUNDLED WITH 4.0.x` installs `bundler 4.0.0`

For example, if your application started failing, using bundler 2.6.1, you could adjust it to instead use the 2.6.x series above which would be:

```
BUNDLED WITH
   2.6.9
```

Applications without a `BUNDLED WITH` value will receive a [default bundler version ](https://devcenter.heroku.com/articles/ruby-support-reference#default-bundler-version).
