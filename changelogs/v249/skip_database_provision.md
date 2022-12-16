## Apps that use the `heroku/ruby` buildpack can now skip automatic database provisioning using an environment variable

When applications are deployed to Heroku, the last buildpack to execute can request add-ons are provisioned via the [`bin/release` interface](https://devcenter.heroku.com/articles/buildpack-api#bin-release). The `heroku/ruby` buildpack checks if the application [contains a Postgres gem](https://github.com/heroku/heroku-buildpack-ruby/blob/104fe3a374e07a8f3723f110c2148d57ecb9ee79/lib/language_pack/ruby.rb#L992-L1008) and requests that Heroku provision a database for the application automatically. Before the pricing change, the database requested was free, and adding this add-on by the buildpack would save developers time while setting up applications.

Developers using the `heroku/ruby` buildpack to deploy new applications who do not want this behavior can now opt out by setting the `HEROKU_SKIP_DATABASE_PROVISION` environment variable:

```shell
$ heroku config:set HEROKU_SKIP_DATABASE_PROVISION=1
```

This setting will prevent the database from being requested. This environment variable only affects `heroku/ruby` users and only affects applications without a successful first deployment. Any already deployed applications that do not want a Heroku database must manually remove their add-on.

This environment variable interface is experimental and subject to change. Before any change, a deprecation warning will be emitted from the `heroku/ruby` buildpack on deployment with additional details.

For more information, see [Ruby database provisioning](https://devcenter.heroku.com/articles/ruby-database-provisioning).
