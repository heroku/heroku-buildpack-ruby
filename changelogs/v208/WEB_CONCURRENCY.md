## New Ruby applications now have a set default value WEB_CONCURRENCY based on dyno type and size

The values for WEB_CONCURRENCY and RAILS_MAX_THREADS are now set for new applications based on the dyno size and type. This will allow a developer upgrading to a performance-l dyno to take advantage of additional physical CPU cores without having to modify environment variables.

Existing applications that want to opt-into having these values set to defaults can do so by setting this configuration value:

```
$ heroku config:set SENSIBLE_DEFAULTS=1
```

For more information see the [Ruby Support documentation](https://devcenter.heroku.com/articles/ruby-support#default-web_concurrency)


----

## Default WEB_CONCURRENCY

For new applications, the values for WEB_CONCURRENCY and RAILS_MAX_THREADS are set by default according to our [recommended Puma configuration](https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#recommended-default-puma-process-and-thread-configuration).

You can see if your application has this set by running `heroku run bash` and then this command:

```
$ cat .profile.d/WEB_CONCURRENCY.sh | grep RAILS_MAX_THREADS
export RAILS_MAX_THREADS=${RAILS_MAX_THREADS:-5}
```

If you see a blank output then this feature is not enabled. To enable this feature for an existing application you can set:

```
$ heroku config:set SENSIBLE_DEFAULTS=1
```

If you still do not see the expected output, it may be due to use of multiple buildpacks and the order they are being invoked. Multiple buildpacks such as the `heroku/nodejs` buildpack also set a default value for `WEB_CONCURRENCY`. When multiple buildpacks set this value, the last one to execute will "win" and those settings will take precedence. To avoid this complication place the `heroku/ruby` buildpack after other buildpacks or manually manage your environment variable values.

