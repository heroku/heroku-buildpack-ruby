 ## The spring library will be disabled in all Ruby applications

The [spring library](https://github.com/rails/spring) is an "application preloader" that is intended to save time between multiple application boots. For example, running the `bin/rails test` command numerous times in a row would be faster with spring. The library accomplishes this performance boost by forking the application after first boot and preserving this fork for future application loads. This behavior has been shown to cause instability and bugs on Heroku. Consequently, all applications using the `heroku/ruby` buildpack will now automatically have spring disabled through the environment variable:

 ```
DISABLE_SPRING=1
 ```

Any benefits that spring provides come from repeatedly calling the same command. However, most commands on Heroku are only run once (`rails server` on boot, for example). As a result, using spring on the system would provide little to no realized practical benefit.

This behavior is now is documented in the [Heroku Ruby Support page](https://devcenter.heroku.com/articles/ruby-support).
