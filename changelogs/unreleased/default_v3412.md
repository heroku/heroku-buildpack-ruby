## Default Ruby version for new apps is now 3.4.12

The [default Ruby version for new Ruby applications is 3.4.12](https://devcenter.heroku.com/articles/ruby-support#default-ruby-version-for-new-apps). You’ll only get the default if the application does not specify a Ruby version.

Heroku highly recommends specifying your desired Ruby version. You can specify a Ruby version in your `Gemfile`:

```ruby
ruby "3.4.12"
```

Once you have a Ruby version specified in your `Gemfile`, update the `Gemfile.lock` by running the following command:

```term
$ bundle update --ruby
```

Make sure you commit the results to git before attempting to deploy again:

```term
$ git add Gemfile Gemfile.lock
$ git commit -m "update ruby version"
```
