# Scalingo buildpack: Ruby

A Scalingo [buildpack](http://doc.scalingo.com/buildpacks) for Ruby based apps (Ruby, Rack, and Rails apps). It uses [Bundler](http://gembundler.com) for dependency management.

This buildpack requires 64-bit Linux.

## Usage

This buildpack will be used if your app has a `Gemfile` and `Gemfile.lock` in the root directory. It will then use Bundler to install your dependencies.

```
Example Usage:
    $ ls
    Gemfile Gemfile.lock

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

## Documentation

For more information about using Ruby and buildpacks on Scalingo, see these documentation articles:

- [Scalingo Ruby Support](http://doc.scalingo.com/languages/ruby)
- [Getting Started with Rails 4 on Scalingo](http://doc.scalingo.com/languages/ruby/getting-started-with-rails.html)
- [Buildpacks](http://doc.scalingo.com/buildpacks)

## Hacking

To use this buildpack, fork it on Github.  Push up changes to your fork, then create a test app with `BUILDPACK_URL=<your-github-url>` and push to it.

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

## Credits

*This buildpack is maintained by Heroku. Upstream Repository: [heroku-ruby-buildpack](https://github.com/heroku/heroku-buildpack-ruby)*
