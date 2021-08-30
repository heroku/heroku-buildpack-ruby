## Ruby buildpack now clears previous default buildpack `WEB_CONCURRENCY` values

Some buildpacks may set a default value for the `WEB_CONCURRENCY` environment variable during dyno startup.

When multiple buildpacks define default values, the declaration from the last buildpack in the list of multiple buildpacks takes precedence, as this is the [primary language of an app](https://devcenter.heroku.com/articles/using-multiple-buildpacks-for-an-app#adding-a-buildpack).

The Ruby buildpack is now interoperable with other buildpacks in this regard; for example, using `heroku/nodejs` as the first, and `heroku/ruby` as the second buildpack, will no longer lead to Node.js default values for `WEB_CONCURRENCY` to apply at runtime.
