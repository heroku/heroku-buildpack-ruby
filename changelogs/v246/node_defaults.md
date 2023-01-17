## Ruby apps now default to Node version 16.18.1 and Yarn version 1.22.19

Applications using the `heroku/ruby` buildpack that do not already have `node`
and/or `yarn` installed by another buildpack (such as the `heroku/nodejs`
buildpack) will now receive:

- Node.js version 16.18.1 (was previously 16.13.1)
- Yarn version 1.22.19 (was previously 1.22.17)

These versions and instructions on how to specify a specific version of these binaries can be found on the [installed binaries section of the Heroku Ruby Support page](https://devcenter.heroku.com/articles/ruby-support#installed-binaries).
