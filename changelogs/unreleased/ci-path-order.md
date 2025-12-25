## Ruby applications using Heroku CI have a different PATH load order

The `PATH` order on Heroku CI relying on `bin/test` interface has changed for applications using the `heroku/ruby` buildpack.

It now starts with:

- `/app/bin:/app/vendor/bundle/bin:/app/vendor/bundle/ruby/<major>.<minor>.0/bin`

> Note `<major>.<minor>` is for the Ruby version so Ruby 3.3.10 would show `/app/vendor/bundle/ruby/3.3.0/bin` on the path .

This matches the behavior of regular `$ git push heroku` deploys and applications specifying a test command via `app.json`.

Previously it started with:

- `/app/bin:vendor/bundle/ruby/<major>.<minor>.0/bin:<bootstrap ruby>/bin:/app/vendor/bundle/ruby/<major>.<minor>.0/bin:/app/vendor/bundle/bin`

This discrepancy between has resulted in zero reported issues or tickets, so the fix is not expected to be disruptive. However, it's still a change, and if your application is affected it helps to understand each of the parts of those path to help with debugging.

## Heroku CI `bin/test`

Only applications that do not specify a test command in their `app.json` will trigger calling `bin/test` of the
buildpack. This `bin/test` runs a Ruby script to determine what test command should be called (such as `bin/rake test`).
Applications relying on this behavior will now get a different `PATH` order.

## What is the `PATH`?

When you type in `$ rspec` the operating system will look for the executable `rspec` by breaking the `PATH` environment variable into parts with a colon (`:`) separator in order from back to front. That means that it will now look for the `rspec` executable in this order:

- `/app/bin/rspec`
- `/app/vendor/bundle/bin/rspec`
- `/app/vendor/bundle/ruby/<major>.<minor>.0/bin/rspec`

By changing the contents or the ordering of the `PATH` you'll possibly change which executable is run. You can see the executable order by using the `which` tool.

```
$ heroku run bash
~ $ which -a rake
/app/bin/rake
/app/vendor/bundle/bin/rake
/app/vendor/bundle/ruby/3.3.0/bin/rake
```

The `-a` flag tells `which` to list all found executables, not just the first. But when you run `$ rake` it will effectively be the same as calling the full path `$ /app/bin/rake` directly.

## Path parts

The following describes the parts that `heroku/ruby` places on the `PATH` both before and after the change.

### App binstubs `/app/bin`

This is the local `./bin` "binstubs" directory that all recent Rails applications have.
In addition, the Ruby buildpack also places a symlink to the `ruby` executable we install there, as
well as other default gems.

This path is first for the current and prior `PATH`.

### Bundler binstubs `/app/vendor/bundle/bin`

The location of binstubs installed by `bundle install`. So if you have `rake` in your `Gemfile` you would get a `/app/vendor/bundle/bin/rake` executable file. Notably, these executables load `bundler/setup`, so if you call `$ /app/vendor/bundle/bin/rake` it's similar to calling `$ bundle exec /app/vendor/bundle/bin/rake`.

Unlike on a local machine, the difference between activating `$ rspec` and `$ bundle exec rspec` is very small, because Heroku cleans unused gem versions. The only time there are multiple versions of a gem on the system is due to default gems or multiple Ruby installations (due to conflicting "bootstrap" Ruby).

This is now second on the `PATH`, previously it was last (as installed by `heroku/ruby`).

> Note that this is bundler version dependent Bundler 2.6 places files here Bundler 2.7+ does not

### RubyGems binstubs`/app/vendor/bundle/ruby/<major>.<minor>.0/bin`

The location of binstubs installed by RubyGems (`gem`). When you `bundle install`, it also installs "binstubs" to this directory. These executables do NOT load bundler, so on Ruby 3.3.10 `$ bundle exec /app/vendor/bundle/ruby/3.3.0/bin/rake` and `$ /app/vendor/bundle/ruby/3.3.0/bin` would possibly produce different results on a system where there are many versions of a default gem installed.

This is now third on the `PATH`, previously it was second as a relative path and again later as an absolute path.

When a relative path is on the `PATH` as the application changes working directories it changes the effective value of the path. For example, `Dir.chdir("tmp")` would trigger path lookups in `tmp/vendor/bundle/ruby/3.3.0/bin` (for Ruby 3.3.10). It's unlikely this affected many people, but the difference is worth noting.

### Bootstrap Ruby `<bootstrap ruby>/bin`

The Ruby buildpack uses a "bootstrap" version of Ruby to execute itself.

Because `/app/bin` is on the path first, the correct version of Ruby will always be used (since that is where we symlink Ruby). However, if you were trying to call a default gem binstub, it's possible that prior to this change, you could have activated the "bootstrap" Ruby's copy instead of the Ruby version you requested.

This is no longer on the path as the implementation was refactored, so it's no longer needed. Previously, it was on the path by necessity of the implementation of `bin/test`.
