## Master

* Better cedar14 Ruby install error message

## v127 (9/18/2014)

* rbx is now stack aware

## v126 (8/4/2014)

* fix bundler cache clearing on ruby version change
* vendor the jvm when yui-compressor is detected

## v125 (8/1/2014)

* bump to node 0.10.30 on cedar-14

## v124 (8/1/2014)

* use node 0.10.29 on cedar-14
* properly use vendored jvm, so not to be dependent on java on the stack image

## v123 (7/25/2014)

* fix permission denied edge cases when copying the bundler cache with minitest

## v122 (7/25/2014)

* handle bundler cache for stack changes on existing apps

## v121 (6/30/2014)

* on new apps, source default envs instead of replacing them
* support different stacks for new apps

## v120 (6/16/2014)

* Bump bundler to 1.6.3 which includes improved dependency resolver

## v119 (5/9/2014)

* Temporarily disable default ruby cache

## v118 (5/6/2014)

* Ruby version detection now loads user environment variables

## v117 (4/14/2014)

Features:


Bugfixes:

* fix anvil use case of multibuildpack with node


## v116 (4/10/2014)

Features:


Bugfixes:

* Revert back to Bundler 1.5.2


## v115 (4/9/2014)

Features:


Bugfixes:

* Add default process types to all apps deployed regardless of `Procfile`

## v114 (4/9/2014)

Features:

* Bundler 1.6.1
* Warn when not using a Procfile (looking at you webrick)

Bugfixes:


## v113 (4/8/2014)

Features:

* use heroku-buildpack-nodejs's node binary
* `CURL_CONNECT_TIMEOUT` and `CURL_TIMEOUT` are configurable as ENV vars

Bugfixes:

* Don't double print "Running: rake assets:precompile" on Ruby apps


## v112 (3/27/2014)

Features:


Bugfixes:

* compile psych with libyaml 0.1.6 for CVE-2014-2525

## v111 (3/20/2014)

Features:


Bugfixes:

* spelling


## v110 (3/20/2014)

Features:

* Better message when running `assets:precompile` without a database

Bugfixes:

## v108 (2/27/2014)

Features:

* parse Bundler patchlevel option

Bugfixes:

* don't let users step on themselves by replacing `env` in `$PATH`

## v107 (2/26/2014)

Features:

Bugfixes:

* more shellescaping bug fixes


## v105

Rollbacked to v103


## v104 (2/26/2014)

Features:

Bugfixes:

* fix bugs in shellescaping (#231)


## v103 (2/18/2014)

Features:

* Rails 4.1.0 Support. Stop writing database.yml and support for secrets.yml by generating SECRET_KEY_BASE for users.

Bugfixes:


## v102 (2/6/2014)

Features:

Bugfixes:

* use blacklist of env vars, so users can't break the build process


## v101 (2/5/2014)

Features:

Bugfixes:

* fix rake detection when DATABASE_URL is not present
* support BUNDLE_WITHOUT when using ponies
* quote ponies env vars, so build doesn't break


## v100 (2/4/2014)

Features:

Bugfixes:

* compile psych with libyaml 0.1.5 for CVE-2013-6393

## v99 (2/4/2014)

Features:

* Noop

Bugfixes:


## v98 (1/30/2014)

Features:

Bugfixes:

* Use vendored JDK binary during build


## v97 (1/30/2014)

Features:

Bugfixes:

* Actually finalize method rename to `install_bundler_in_app`


## v96 (1/29/2014)

Features:

Bugfixes:

* Finalize method rename to `install_bundler_in_app`

## v95

Rollback to v93

## v94 (1/29/2014)

Features:

Bugfixes:

* Fixed `uninitialized constant Rake::DSL` error when running rake tasks on Ruby 1.9.2

## v93 (01/28/2014)

Features:

* buildpack-env-arg (ponies) support

Bugfixes:

## v92 (01/27/2014)

Features:

Bugfixes:

* Only display rake error messages if a `Rakefile` exists
* when detecting for ruby version, don't use stderr messages

## v91 (01/16/2014)

Features:

* Parallel gem installation with bundler 1.5.2

Bugfixes:


## v90 (01/09/2014)

Features:

* Rollback v89 due to bug in bundler 1.5.1

Bugfixes:

## v89 (01/09/2014)

Features:

* Use most recent version of bundler with support for parallel Gem installation

Bugfixes:

## v86 (12/11/2013)

Features:

Bugfixes:

* Windows warnings will now display before bundle install, this prevents an un-resolvable `Gemfile` from erroring which previously prevented the warning roll up from being shown. When this happened the developer did not see that we are clearing the `Gemfile.lock` from the git repository when bundled on a windows machine.
* Checks for `public/assets/manifest*.json` and `public/assets/manifest.yml` will now come before Rake task detection introduced in v85.

## v85 (12/05/2013)

Features:


Bugfixes:

* Any errors in a Rakefile will now be explicitly shown as such instead of hidden in a `assets:precompile` task detection failure (#171)
* Now using correct default "hobby" database #179

## v84 (11/06/2013)

Features:

* Any Ruby app with a rake `assets:precompile` task present that does not run successfully will now fail. This matches the current behavior of Rails 3 and 4 deploys.


Bugfixes:

* Fix default gem cache

## v83 (10/29/2013)

Features:

* RubyVersion extracted into its own class
* Release no longer requires language_pack
* Detect no longer requires language_pack
* Downloads with curl now retry on failed connections, pass exit status appropriately

Bugfixes:

* Errors in Gemfiles will no longer show up as bad ruby versions #36
* Fix warning warning libjffi-1.2.so on < JRuby 1.7.3

## v82 (10/28/2013)

Bugfixes:

* Rails 3 deploys that do not successfully run `assets:precompile` will now fail.

## v81 (10/15/2013)

Features:

* add Default Bundler Cache for new Ruby 2.0.0 apps
* use Virginia S3 bucket instead of Cloudfront

## v80 (9/23/2013)

Features:

* Cache 50mb of Rails 4 intermediate cache
* Support for Ruby 2.1.0

Bugfixes:

* Disable invoke dynamic on JRuby by default until JDK stabalizes it

## v79 (9/3/2013)

Bugfixes:

* Remove LPXC debug output when `DEBUG` env var is set (#141)
* Symlink ruby.exe, so Rails 4 bins work for Windows (#139)

## v78 (8/28/2013)

Features:

* Don't add plugins if already gems

Bugfixes:

* Fix issue #127 Race condition with LPXC

## v77 (8/5/2013)

Features:

* Force nokogiri to compile with system libs

## v76 (7/29/2013)

Bugfixes:

* fix request_id for instrumentation to follow standard

## v75 (7/29/2013)

Features:

* add request_id to instrumentation
* switchover to rubinius hosted rbx binaries

Bugfixes:

* OpenJDK version was rolled back, stop special casing JRuby 1.7.3.

## v74 (7/24/2013)

Bugfixes:

* Lock JRuby 1.7.3 and lower to older version of JDK due to <https://github.com/jruby/jruby/issues/626>

## v73 (7/23/2013)

* Revert to v69 due to asset:precompile bugs

## v72 (7/23/2013)

Bugfixes:

* Fix rake task detection for Rails 3 (@hynkle, #118)

## v71 (7/18/2013)

* Revert to v69 due to asset:precompile bugs

## v70 (7/18/2013)

Bugfixes:

* Don't silently fail rake task checks (@gabrielg, #34)

## v69 (7/16/2013)

Bugfixes:

* Add spacing to end of instrumentation

## v68 (7/16/2013)

Features:

* Log buildpack name and entering rails3/4 compile

## v67 (7/10/2013)

Features:

* Fetcher uses CDN if available
* Add buildpack_version to the instrumentation output

Bugfixes:

* Don't print DEBUG messages for lxpc when env var is present
* Fix ruby gemfile warning line for JRuby

## v66 (7/9/2013)

Bugfixes:

* Include logtoken properly

## v65 (7/9/2013)

Features:

* Instrument timing infrastructure for the buildpack

Bugfixes:

* Fix DATABASE_URL to use jdbc-postgres for JRuby (@jkrall, #116)

## v64 (6/19/2013)

Features:

* only download one copy of bundler per process (@dpiddy, #69)
* roll up all warnings for end of push output
* write database.yml for Rails 4

Bugfixes:

* fix sqlite3 error messaging detection

## v63 (6/17/2013)

Features:

* Lock default ruby if default ruby is used
* Change default ruby to 2.0.0
* Stop using the stack image ruby and always vendor ruby

## v62 (5/21/2013)

Bugfixes:

* Correctly detect asset manifest files in Rails 4
* Fix jruby 1.8.7 bundler/psych require bug

## v61 (4/18/2013)

Features:

* Start caching the rubygems version used.

Bugfixes:

* Rebuild bundler cache if rubygems 2 is detected. Bugfixes in later rubygems.

## v60 (4/17/2013)

Security:

* Disable Java RMI Remote Classloading for CVE-2013-1537, <https://bugzilla.redhat.com/show_bug.cgi?id=952387>

## v59 (4/4/2013)

Bugfixes:

* Change JVM S3 bucket

## v58 (3/19/2013)

Bugfixes:

* Fix ruby 1.8.7 not being able to compile native extensions

## v57 (3/18/2013)

Bugfixes:

* Fix git gemspec bug in bundler

## v56 (3/11/2013)

Bugfixes:

* Upgrade bundler to 1.3.2 to fix --dry-clean/Would have removed bug in bundle clean, part 2.

## v55 (3/7/2013)

Bugfixes:

* Revert back to Bundler 1.3.0.pre.5, see https://gist.github.com/mattonrails/e063caf86962995e7ba0

## v54 (3/7/2013)

Bugfixes:

* Upgrade bundler to 1.3.2 to fix --dry-clean/Would have removed bug in bundle clean

## v53 (3/6/2013)

Bugfixes:

* bin/detect for Rails 3 and 4 will use railties for detection vs the rails gem
* bin/detect does not error out when Gemfile + Gemfile.lock are missing

## v52 (2/25/2013)

Bugfixes:

* Revert back to 1.3.0.pre.5 due to bundler warnings

## v51 (2/25/2013)

Features:

* Initial Rails 4 beta support
* Upgrade bundler to 1.3.0

Bugfixes:

* Better buildpack detection through Gemfile.lock gems

## v50 (1/31/2013)

Features:

* Restore ruby deploys back to normal

## v49 (1/30/2013)

Features:

* Re-enable ruby deploys for apps just using the heroku cache
* Display ruby version change when busting the cache

## v48 (1/30/2013)

Features:

* Update deploy error message copy to link to status incident.

## v47 (1/30/2013)

Features:

* Disable ruby deploys due to rubygems.org compromise

## v46 (1/10/2013)

Features:

* Upgrade Bundler to 1.3.0.pre.5
* bundler binstubs now go in vendor/bundle/bin

## v45 (12/14/2012)

Features:

* Stop setting env vars in bin/release now that login-shell is released
* Enable Invoke Dynamic on JRuby by default
* GEM_PATH is now updated on each push

## v44 (12/14/2012)

Faulty Release

## v43 (12/13/2012)

Features:

* Upgrade Bundler to 1.3.0.pre.2

## v42 (11/26/2012)

Features:

* Upgrade Bundler to 1.2.2 to fix Ruby 2.0.0/YAML issues

## v41 (11/1/2012)

Features:

* Enable ruby 2.0.0 support for testing

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
