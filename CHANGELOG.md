## v40 (10/14/2012)

Features:

* Cache version of the buildpack we used to deploy
* Purge cache when v38 is detected

## v39 (10/14/2012)

Bugfixes:

* Don't display cache clearing message for new apps
* Actually clear bundler cache on ruby version change

## v38 (10/14/2012)

Bugfixes:

* Stop bundle cache from continually growing

## v37 (10/12/2012)

Bugfixes:

* Remove temporary workaround from v36.
* Clear bundler cache upon Ruby version change

## v36 (10/12/2012)

Bugfixes:

* Always clear the cache for ruby 1.9.3 as a temporary workaround due to the security upgrade

## v35 (9/19/2012)

Features:

* Upgrade to Bundler 1.2.1
* Display bundle clean output
* More resilent to rubygems.org API outages

Bugfixes:

* `bundle clean` works again

## v34 (8/30/2012)

Features:

* Upgrade to Bundler 1.2.0

## v33 (8/9/2012)

Features:

* Upgrade to Bundler 1.2.0.rc.2
* vendor JDK7 for JRuby, but disable invoke dynamic

## v29 (7/19/2012)

Features:

* support .profile.d/ruby.sh
* sync stdout so that the buildpack streams even in non-interactive shells
* Upgrade to Bundler 1.2.0.rc

## v28 (7/16/2012)

Features:

* Vendor OpenJDK6 into slug when using JRuby
* ruby version support for ruby 1.8.7 via bundler's ruby DSL

Bugfixes:

* sqlite3 error gets displayed again

## v27 (6/14/2012)

Bugfixes:

* Remove `vendor/bundle` message only appears when dir actually exists

## v26 (6/14/2012)

Features:

* print message when assets:precompile finishes successfully
* Remove `vendor/bundle` if user commits it to their git repo.

## v25 (6/12/2012)

Features:

* support "ruby-xxx-jruby-yyy" for jruby detection packages

## v24 (6/7/2012)

Features:

* removes bundler cache in the slug, to minimize slug size (@stevenh512, #16)
* optimize push time with caching

## v23 (5/8/2012)

Bugfixes:

* fix ruby version bug with "fatal:-Not-a-git-repository"

## v22 (5/7/2012)

Features:

* bundler 1.2.0.pre
* ruby version support for ruby 1.9.2/1.9.3 via bundler's ruby DSL

Deprecation:

* ENV['RUBY_VERSION'] in favor of bundler's ruby DSL

## v21 (3/21/2012)

Features:

* bundler 1.1.2

## v20 (3/12/2012)

Features:

* bundler 1.1.0 \o/

## v19 (1/25/2012)

Bugfixes:

* fix native extension building for rbx 2.0.0dev

## v18 (1/18/2012)

Features:

* JRuby support
* rbx 2.0.0dev support

Bugfixes:

* force db password to be a string in the yaml file

## v17 (12/29/2011)

Features:

* bundler 1.1.rc.7

## v16 (12/29/2011)

Features:

* pass DATABASE_URL to rails 3.1 assets:precompile rake task detection

## v15 (12/27/2011)

Features:

* bundler 1.1.rc.6

## v14 (12/22/2011)

Bugfixes:

* stop freedom patching syck in ruby 1.9.3+

## v13 (12/15/2011)

Features:

* bundler 1.1.rc.5

## v12 (12/13/2011)

Bugfixes:

* syck workaround for yaml/psych issues

## v11 (12/12/2011)

Features:

* bundler 1.1.rc.3

## v10 (11/23/2011)

Features:

* bundler binstubs
* dynamic slug_vendor_base detection

Bugfixes:

* don't show sqlite3 error if it's in a bundle without group on failed bundle install

## v9 (11/14/2011)

Features:

* rbx 1.2.4 support
* print out RUBY_VERSION being used

Bugfixes:

* don't leave behind ruby_versions.yml

## v8 (11/8/2011)

Features:

* use vm as part of RUBY_VERSION

## v7 (11/8/2011)

Features:

* ruby 1.9.3 support
* specify ruby versions using RUBY_VERSION build var

Bugfixes:

* move "bin/" to the front of the PATH, so apps can override existing bins

## v6 (11/2/2011)

Features:

* add sqlite3 warning when detected on bundle install error

Bugfixes:

* Change gem detection to use lockfile parser
* use `$RACK_ENV` when thin is detected for rack apps
