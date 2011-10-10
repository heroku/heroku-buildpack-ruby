# Ruby Language Pack

The Ruby Language Pack requires a `Gemfile` and `Gemfile.lock` file to be recognized as a ruby app. It will then proceed to run `bundle install` after setting up the appropriate environment for [ruby](http://ruby-lang.org) and [bundler](http://gembundler.com).

## Bundler

For non-windows `Gemfile.lock` files, the `--deployment` flag will be used. The `vendor/bundle` directory is cached between builds to allow for faster `bundle install` times. `bundle clean` is used to ensure no stale gems are stored between builds.

## Rails

A [rails_log_stdout](http://github.com/ddollar/rails_log_stdout) is installed by default so Rails' logger will log to STDOUT and picked up by Heroku's [logplex](http://github.com/heroku/logplex).

## Rails 3

To enable static assets being served on the dyno, [rails3_serve_static_assets](http://github.com/pedro/rails3_serve_static_assets) is installed by default. If the [execjs gem](http://github.com/sstephenson/execjs) is detected then [node](http://github.com/joyent/node) will be vendored. The `assets:precompile` rake task will get run if no `public/manifest.yml` is detected.  See [this article](http://devcenter.heroku.com/articles/rails31_heroku_cedar) on how rails 3.1 works on cedar.

## Auto Injecting Plugins

Any vendored plugin can be stopped from being installed by creating the directory it's installed to in the slug. For instance, to prevent rails_log_stdout plugin from being injected, add `vendor/plugins/rails_log_stdout/.gitkeep` to your git repo.

## Ruby Language Pack Flow

Here's the basic flow of how the language pack works:

Ruby (Gemfile and Gemfile.lock is detected)

* runs bundler
* installs binaries
  * installs node if the gem execjs is detected

Rack (config.ru is detected)

* everything from Ruby
* sets RACK_ENV=production

Rails 2 (config/environment.rb is detected)

* everything from Rack
* sets RAILS_ENV=production
* install rails 2 plugins
  * [rails_log_stdout](http://github.com/ddollar/rails_log_stdout)

Rails 3 (config/application.rb is detected)

* everything from Rails 2
* install rails 3 plugins
  * [rails3_server_static_assets](https://github.com/pedro/rails3_serve_static_assets)
* runs `rake assets:precompile` if the rake task is detected

## Usage

Add this language pack to your `LANGUAGE_PACK_URL`.

    heroku config:add LANGUAGE_PACK_URL="http://github.com/heroku/language-pack-ruby.git"

## Vendored Libraries

The `Rakefile` consists of tools used to help with vendoring libraries. You'll need the [vulcan](http://github.com/ddollar/vulcan) gem to build binaries on heroku. We also use [Amazon's S3](http://aws.amazon.com/s3/) to store all of our vendored libraries. The rake tasks create tarballs which are referenced by the language pack and unpacked during slug compilation.
