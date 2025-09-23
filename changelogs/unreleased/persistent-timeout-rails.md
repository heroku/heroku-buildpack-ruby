## Rails apps now have `PUMA_PERSISTENT_TIMEOUT=95` set by default

Previously, this setting was only applied to [Rack applications](https://devcenter.heroku.com/changelog-items/3391). With this change, all Ruby applications now have the `PUMA_PERSISTENT_TIMEOUT` environment variable set to a default value of `95`.

Puma [7.0.3+](https://github.com/puma/puma/pull/3378) introduced the ability to configure the `persistent_timeout` value via an environment variable. Router 2.0 uses an idle timeout value of 90s https://devcenter.heroku.com/articles/http-routing#keepalives. To avoid a situation where a request is sent right before Puma closes the connection, the value needs to be slightly higher than the Router's value.

Applications that are not on Puma 7.0.3+ can use it manually in their `config/puma.rb` file:

```ruby
# config/puma.rb

# Only required for Puma 6 and below
persistent_timeout(ENV.fetch("PUMA_PERSISTENT_TIMEOUT") { 95 }.to_i)
```

Other web server users can use this as a stable interface to retrieve a suggested idle timeout setting.
