Cloud Foundry Ruby Buildpack
============================

This is a fork of the [Heroku Ruby build pack](https://github.com/heroku/heroku-buildpack-ruby) designed to support Cloud Foundry
on premises installations.

This buildpack allows the Ruby Buildpack to work with Cloud Foundry.

Notes to buildpack developers
=============================

* Does not use Heroku pre-cached gems. This avoids an issue with the Postgres gem's binary compatibility with ElephantSQL.
