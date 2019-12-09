## Postgresql client library libpq version 5.12.1 now vendored into Ruby applications on Heroku-18

Ruby applications deploying to Heroku-18 will get a vendored version of the libpq client library version 5.12.1 starting today. For more information about the reasons for this change and the possible effects see:

https://devcenter.heroku.com/articles/libpq-5-12-1-breaking-connection-behavior

If your application breaks due to this change you can rollback to your last build. You can also temporarially opt out of this behavior by setting:

```
$ heroku config:set HEROKU_SKIP_LIBPQ12=1
```

In the future libpq 5.12 will be the default on the platform and you will not be able to opt-out of the library. For more information see:

https://devcenter.heroku.com/articles/libpq-5-12-1-breaking-connection-behavior
