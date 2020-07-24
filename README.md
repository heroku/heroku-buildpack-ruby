# Heroku Buildpack for Ruby
![ruby](https://cloud.githubusercontent.com/assets/51578/13712725/3c6b3368-e793-11e5-83c1-728440111358.png)

This is a [Heroku Buildpack](http://devcenter.heroku.com/articles/buildpacks) for Ruby, Rack, and Rails apps. It uses [Bundler](https://bundler.io) for dependency management.

This buildpack requires 64-bit Linux.

## Usage

### Ruby

Example Usage:

    $ ls
    Gemfile Gemfile.lock

    $ heroku create --buildpack heroku/ruby

    $ git push heroku main
    ...
    -----> Heroku receiving push
    -----> Fetching custom buildpack
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

The buildpack will detect your app as Ruby if it has a `Gemfile` and `Gemfile.lock` files in the root directory. It will then proceed to run `bundle install` after setting up the appropriate environment for [ruby](http://ruby-lang.org) and [Bundler](https://bundler.io).

## Documentation

For more information about using Ruby and buildpacks on Heroku, see these Dev Center articles:

- [Heroku Ruby Support](https://devcenter.heroku.com/articles/ruby-support)
- [Getting Started with Ruby on Heroku](https://devcenter.heroku.com/articles/getting-started-with-ruby)
- [Getting Started with Rails 4 on Heroku](https://devcenter.heroku.com/articles/getting-started-with-rails4)
- [Buildpacks](https://devcenter.heroku.com/articles/buildpacks)
- [Buildpack API](https://devcenter.heroku.com/articles/buildpack-api)

## Hacking

To use this buildpack, fork it on Github.  Push up changes to your fork, then create a test app with `--buildpack <your-github-url>` and push to it.

### Testing

The tests on this buildpack are written in Rspec to allow the use of
`focused: true`. Parallelization of testing is provided by
https://github.com/grosser/parallel_tests this lib spins up an arbitrary
number of processes and running a different test file in each process,
it does not parallelize tests within a test file. To run the tests: clone the repo, then `bundle install` then clone the test fixtures by running:

```sh
$ bundle exec hatchet install
```

```sh
$ bundle exec rake spec
```
