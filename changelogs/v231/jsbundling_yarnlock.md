## Yarn will now be installed for Ruby applications that have a `yarn.lock` file

Ruby applications using the `heroku/ruby` buildpack now receive a default version of `yarn` installed if they have a `yarn.lock` file in the root directory of their application.

Prior to this change, only applications using the `webpacker` gem would trigger node installation logic. This change is intended to facilitate Rails 7 applications using `jsbundling-rails` without `webpacker`.

>Note
>Applications using the `heroku/nodejs` buildpack before the `heroku/ruby` buildpack will not see a change in behavior

For more information, see [Heroku Ruby support documentation](https://devcenter.heroku.com/articles/ruby-support#installed-binaries).
