## Native Gemfile.lock support for Windows Ruby users with Bundler 2.2+

Ruby applications that use Windows and Bundler 2.2+ will no longer have their `Gemfile.lock` deleted and re-generated on deployment. Instead, they will rely on Bundler 2.2+'s support for multiple platforms to correctly resolve dependencies. We recommend any Windows Ruby user to upgrade their Bundler version in the `Gemfile.lock` to Bundler 2.2+ to take advantage of this behavior:

> note
> The leading `>` indicates a command prompt and should not be copied.

```
> gem install bundler
> bundle update --bundler
> bundle lock --add-platform ruby
> bundle lock --add-platform x86_64-linux
> bundle install
> git add Gemfile.lock
> git commit -m "Upgrade bundler"
```

This change is reflected in the [Deploying a Ruby Project Generated on Windows](https://devcenter.heroku.com/articles/bundler-windows-gemfile) Dev Center article. More information on the history of the behavior can be found [on this GitHub issue](https://github.com/heroku/heroku-buildpack-ruby/issues/1157).

<!--

https://devcenter.heroku.com/admin/articles/315/edit

# Using Bundler

To use, install bundler run:

> note
> Commands are prefixed with `>` to indicate they should be run in a command prompt, do not copy the `>` character.

```term
> gem install bundler
```

Create a file named `Gemfile` in the root of your app specifying what gems are required to run it:

```ruby
source "https://rubygems.org"

gem 'sinatra', '4.0'
```

This file should be added to the git repository since it is part of the app. You should also add the `.bundle` directory to your `.gitignore` file. Once you have added the `Gemfile`, it makes it easy for other developers to get their environment ready to run the app:

```term
> bundle install
```

This command ensures that all gems specified in the `Gemfile` are available for your application. Running `bundle install` also generates a `Gemfile.lock`, which should be added to your git repository. The `Gemfile.lock` ensures that deployed versions of gems on Heroku match the version installed locally on your development machine.

>warning
>If your `Gemfile.lock` specifies a bundler version prior to 2.2 and the `PLATFORMS` section of your `Gemfile.lock` contains Windows entries, such as `mswin` or `mingw`, then the `Gemfile.lock` file will be ignored on Heroku. We recommend upgrading to Bundler 2.2 or later.

## Windows support with Bundler 2.2 and later

Heroku supports deploying applications developed on Windows, but [production dynos will be run on a different operating system](https://devcenter.heroku.com/articles/stack)). To ensure that your Heroku production application installs the same versions of gems you are using locally for development on your Windows machine, we recommend updating your application to Bundler 2.2 or later. You can upgrade your bundler version by running the following commands:

```
> gem install bundler
> bundle update --bundler
> bundle lock --add-platform ruby
> bundle lock --add-platform x86_64-linux
> bundle install
> git add Gemfile.lock
> git commit -m "Upgrade bundler"
```

After running these commands, Windows applications using bundler 2.2+ will rely on bundler's support for multiple platforms to find and install an appropriate version.

## Windows support with bundler before 2.2

If your application cannot upgrade to bundler 2.2 or later, then when you deploy, the `Gemfile.lock` file will be deleted and regenerated. More information about [this behavior can be found on the Ruby buildpack's GitHub repository](https://github.com/heroku/heroku-buildpack-ruby/issues/1157).
-->
