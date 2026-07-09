# Ruby applications no longer receive `rake` process type

Applications using the `heroku/ruby` buildpack will no longer receive a default `rake` process type. This change aligns `heroku run rake` to behave the same as invoking `rake` at build or runtime.

## About helper process types

Heroku process types are used for defining a runnable group, such as `heroku ps:scale web=1`. These process groups can also be used with the CLI command `heroku run web`. The `heroku/ruby` buildpack uses this functionality to set convenient aliases, the most notable is:

```term
$ heroku run console
```

For Ruby applications `console` is a process type that is used as an alias to `irb` while Rails applications will run a `rails console`.

Prior to this change, `rake` was aliased to `bundle exec rake`, which will behave similarly for most Ruby customers. However, customers who have a custom `rake` binstub, such as `bin/rake`, will get one executable invoked at build and runtime, and a possibly different executable invoked at `heroku run rake` time, which makes debugging harder.

Now, when `heroku run rake` is used, it will perform a lookup on the `PATH` and invoke the same `rake` executable that is used at build and runtime. You can see the resolved `rake` executable location by running:

```term
$ heroku run "which rake"
```
