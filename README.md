# Scalingo buildpack: Ruby

A Scalingo [buildpack](http://doc.scalingo.com/buildpacks) for Ruby based apps (Ruby, Rack, and Rails apps). It uses [Bundler](http://gembundler.com) for dependency management.

This buildpack requires 64-bit Linux.

## Usage

This buildpack will be used if your app has a `Gemfile` and `Gemfile.lock` in the root directory. It will then use Bundler to install your dependencies.

```
    $ scalingo create ruby-app

    $ git push scalingo master
    ...
    -----> Ruby app detected
    -----> Installing dependencies using Bundler version 1.1.rc
           Running: bundle install --without development:test --path vendor/bundle --deployment
           Fetching gem metadata from http://rubygems.org/..
           Installing rack (1.3.5)
           Using bundler (1.1.rc)
           Your bundle is complete! It was installed into ./vendor/bundle
           Cleaning up the bundler cache.
    -----> Discovering process types
           Procfile declares types -> (none)
           Default types for Ruby  -> console, rake
```

The buildpack will detect your app as Ruby if it has a `Gemfile` and `Gemfile.lock` files in the root directory. It will then proceed to run `bundle install` after setting up the appropriate environment for [ruby](http://ruby-lang.org) and [Bundler](https://bundler.io).

#### Bundler

For non-windows `Gemfile.lock` files, the `--deployment` flag will be used. In the case of windows, the Gemfile.lock will be deleted and Bundler will do a full resolve so native gems are handled properly. The `vendor/bundle` directory is cached between builds to allow for faster `bundle install` times. `bundle clean` is used to ensure no stale gems are stored between builds.

### Rails 2

Example Usage:

```
    $ ls
    app  config  db  doc  Gemfile  Gemfile.lock  lib  log  public  Rakefile  README  script  test  tmp  vendor

    $ scalingo create ruby-app

    $ git push scalingo master
    -----> Ruby/Rails app detected
    -----> Installing dependencies using Bundler version 1.1.rc
           Running: bundle install --without development:test --path vendor/bundle --deployment
           ...
    -----> Writing config/database.yml to read from DATABASE_URL
    -----> Preparing app for Rails asset pipeline
           Running: rake assets:precompile
    -----> Rails plugin injection
           Injecting rails_log_stdout
           Injecting rails3_serve_static_assets
    -----> Discovering process types
           Procfile declares types      -> web
           Default types for Ruby/Rails -> console, rake, worker
```

The buildpack will detect your apps as a Rails 3 app if it has an `application.rb` file in the `config` directory.

#### Rails Log STDOUT

A [rails_log_stdout](http://github.com/ddollar/rails_log_stdout) is installed by default so Rails' logger will log to STDOUT and picked up by Scalingo's log aggregation system.

#### Assets

To enable static assets being served from the web containers, [rails3_serve_static_assets](http://github.com/pedro/rails3_serve_static_assets)
is installed by default. If the [execjs gem](http://github.com/sstephenson/execjs) is detected then
[node.js](http://github.com/joyent/node) will be vendored. The `assets:precompile` rake task will get run if no `public/manifest.yml` is
detected.

## Documentation

For more information about using Ruby and buildpacks on Scalingo, see these documentation articles:

- [Scalingo Ruby Support](http://doc.scalingo.com/languages/ruby)
- [Getting Started with Rails 4 on Scalingo](http://doc.scalingo.com/languages/ruby/getting-started-with-rails.html)
- [Buildpacks](http://doc.scalingo.com/buildpacks)

## Hacking

To change the vendored binaries for Bundler, [Node.js](http://github.com/joyent/node), and rails plugins, use the rake tasks provided by the `Rakefile`. You'll need an S3-enabled AWS account and a bucket to store your binaries in as well as [Docker](https://docker.io) to build compatible binaries for Scalingo's platform.

For example, you can change the vendored version of Bundler to 1.1.rc.

First you'll need to build a Scalingo-compatible version of Node.js:

    $ export AWS_ID=xxx AWS_SECRET=yyy S3_BUCKET=zzz
    $ s3 create $S3_BUCKET
    $ rake gem:install[bundler,1.1.rc]

Open `lib/language_pack/ruby.rb` in your editor, and change the following line:

    BUNDLER_VERSION = "1.11.2"

Open `lib/language_pack/base.rb` in your editor, and change the following line:

    VENDOR_URL = "https://s3.amazonaws.com/zzz"

Commit and push the changes to your buildpack to your Github fork, then push your sample app to Scalingo to test. You should see:

    -----> Installing dependencies using Bundler version 1.1.rc

`buildpack-build` will create a buildpack in one of two modes and upload it to your local bosh-lite based Cloud Foundry installations.

### Testing

The tests on this buildpack are written in Rspec to allow the use of
`focused: true`. Parallelization of testing is provided by
https://github.com/grosser/parallel_tests this lib spins up an arbitrary
number of processes and running a different test file in each process,
it does not parallelize tests within a test file. To run the tests: clone the repo, then `bundle install` then clone the test fixtures by running:

```sh
$ bundle exec hatchet install
```

then go to [hatchet](https://github.com/heroku/hatchet) repo and follow the
instructions to set it up.

Now run the tests:

```sh
$ bundle exec parallel_rspec -n 6 spec/
```

If you don't want to run them in parallel you can still:

```sh
$ bundle exec rake spec
```

Now go take a nap or do something for a really long time.
