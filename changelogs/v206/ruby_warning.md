## Using old and EOL versions of Ruby now generate warnings

If your application is using a version of MRI Ruby that is below the latest released patch level, you'll now receive a warning on deploy in the build output. For example, if you are using `2.3.3`, you'll be encouraged to upgrade to the latest in the series which is `2.3.8`.

In addition to the version warning, you'll now receive warnings when you're using a version of Ruby that may be EOL (End of Life) soon or is already EOL. Ruby Core officially supports up to 3 releases of Ruby at a time. For example, when `2.7` is released, then the supported versions will be `2.7.x`, `2.6.x`, and `2.5.x`. Our support mirrors Ruby Core support. You can see the [latest versions of Ruby available on our Ruby support page](https://devcenter.heroku.com/articles/ruby-support#supported-runtimes).

Right now you'll receive a warning indicating that your version of Ruby is close to being EOL if you're using `2.4.x`. If you're using `2.3.x` or older, you'll receive a warning indicating that your version is already EOL and we will not be providing support or security patches for the version.

We highly recommend staying on a non-EOL version of Ruby and using the latest patch release as these versions contain the most up to date security and bug fixes.