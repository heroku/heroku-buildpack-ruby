## JVM support for JRuby apps is now provided by the `heroku/jvm` buildpack

JRuby applications require the JVM to run. Before this change, the JVM for JRuby apps was provided by the `heroku/ruby` buildpack for JRuby applications.

Now the custom JVM installation logic in the `heroku/ruby` buildpack has been removed, and instead, the `heroku/jvm` buildpack will be called directly by the Ruby buildpack.

Instead of relying on this functionality, it is recommended to manually require the `heroku/jvm` buildpack for your application:

```
$ heroku buildpacks:add heroku/jvm --index=1
```

For more information on JRuby support, see the [Heroku Ruby Support page](https://devcenter.heroku.com/articles/ruby-support).
