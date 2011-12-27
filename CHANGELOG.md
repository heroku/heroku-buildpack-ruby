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
