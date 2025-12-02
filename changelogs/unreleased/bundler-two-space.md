## Support two space `BUNDLED WITH` indented `Gemfile.lock`

The `Gemfile.lock` file generated with the latest version of Bundler [now uses two spaces instead of three](https://github.com/ruby/rubygems/pull/9076). The `heroku/ruby` buildpack now supports this format.
