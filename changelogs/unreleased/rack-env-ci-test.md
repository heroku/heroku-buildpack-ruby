## Heroku CI now sets `RACK_ENV=test` for all Ruby applications

Previously, only Rails applications running on Heroku CI would have `RACK_ENV` and `RAILS_ENV` set to `test`. Non-Rails [Ruby applications](https://devcenter.heroku.com/articles/ruby-support-reference) (such as Sinatra or plain Rack apps) would incorrectly receive `RACK_ENV=production` during CI test runs.

Now, all Ruby applications running on Heroku CI will have `RACK_ENV=test` set by default. This ensures that test-specific configurations are properly loaded and prevents issues with gems like DatabaseCleaner that have safeguards against running in production environments.

If your application relies on the previous behavior, you can explicitly set `RACK_ENV` in your `app.json`:

```json
{
  "environments": {
    "test": {
      "env": {
        "RACK_ENV": "production"
      }
    }
  }
}
```

