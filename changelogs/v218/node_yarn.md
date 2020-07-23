## Ruby apps now default to Node version 12.16.2 and Yarn version 1.22.4

Applications using the `heroku/ruby` buildpack that do not have a version of Node installed by another buildpack (such as the `heroku/nodejs` buildpack) will now receive:

- Node version 12.16.2 (was previously 10.15.3)
- Yarn version 1.22.4 (was previously 1.16.0)

These versions and instructions on how to specify a specific version of these binaries can be found on the [installed binaries section of the Heroku Ruby Support page](https://devcenter.heroku.com/articles/ruby-support#installed-binaries).
