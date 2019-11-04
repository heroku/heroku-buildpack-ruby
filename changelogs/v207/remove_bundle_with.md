## Ruby apps will now have the `BUNDLED WITH` declaration in their `Gemfile.lock` removed after detecting Bundler version

The version listed in the `BUNDLED WITH` key of the `Gemfile.lock` is used by Heroku to [detect what version of Bundler to use](https://devcenter.heroku.com/articles/ruby-support#libraries).

This declaration is also used internally by an integration between RubyGems and Bundler to attempt to recognize version differences and raise an error. This logic contains bugs and has been embeded in many versions of already released for many existing Ruby versions. In an effort to remove false errors from application deployments, the `BUNDLED WITH` declaration will now be removed from the `Gemfile.lock` after it has been used to determine and install a compatible version of Bundler for the application.

A message will be emitted in the build process when this happens:

```
-----> Removing BUNDLED WITH version in the Gemfile.lock
```