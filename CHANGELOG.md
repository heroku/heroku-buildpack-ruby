## Master

* Set memory default for Node builds (https://github.com/heroku/heroku-buildpack-ruby/pull/861)
* Default Ruby version is now 2.5.5, was previously 2.5.3 (https://github.com/heroku/heroku-buildpack-ruby/pull/863)
* Default Node version is now 10.15.3 and default Yarn version is now 1.16.0 (https://github.com/heroku/heroku-buildpack-ruby/pull/884)

## v200 (3/7/2019)

* Fix: Environment variables not being exported for other buildpacks in CI (https://github.com/heroku/heroku-buildpack-ruby/pull/858)
* Ignore invalid byte encodings when detecting rails config (https://github.com/heroku/heroku-buildpack-ruby/pull/854)

## v199 (2/19/2019)

* Add support for arbitrary Bundler major versions, most notably bundler 2 (https://github.com/heroku/heroku-buildpack-ruby/pull/850)

## v198 (1/17/2019)

* Rev-default Ruby version to be the latest patch release of last years Ruby version 2.5.3 (https://github.com/heroku/heroku-buildpack-ruby/pull/846)
* Allow apps to enable `RUBYOPT=--jit` (https://github.com/heroku/heroku-buildpack-ruby/pull/848)

## v197 (12/18/2018)

* Upgrade node version (https://github.com/heroku/heroku-buildpack-ruby/pull/831)
* Upgrade yarn version (https://github.com/heroku/heroku-buildpack-ruby/pull/832)

## v196 (10/31/2018)

* Delete the sprockets temp directory for a smaller runtime slug if they are not building assets at runtime (https://github.com/heroku/heroku-buildpack-ruby/pull/812)

## v195 (10/18/2018)

* Default Ruby version is now 2.4.5 (https://github.com/heroku/heroku-buildpack-ruby/pull/821)

## v194 (10/16/2018)

* Do not add the `jobs:work` command if an app does not have that rake task available (https://github.com/heroku/heroku-buildpack-ruby/pull/810)

## v193 (9/14/2018)

* Fix link (https://github.com/heroku/heroku-buildpack-ruby/pull/811)

## v192 (9/14/2018)

* Add error messages when using unsupported Ruby versions on the Heroku-18 stack (https://github.com/heroku/heroku-buildpack-ruby/pull/809)

## v191 (8/23/2018)

* Warn when `config.action_dispatch.x_sendfile_header` is set but apache and nginx are not being used (https://github.com/heroku/heroku-buildpack-ruby/pull/795)

## v190 (7/24/2018)

* Support TAP output for Heroku CI (https://github.com/heroku/heroku-buildpack-ruby/pull/790).

## v189 (7/10/2018)

* Colorize build failures and warnings. (https://github.com/heroku/heroku-buildpack-ruby/pull/788)

## v188 (6/26/2018)

* Fix rails config detect timeout. Addreses the process deadlock when detecting rails config that contains an infinite task. This was originally addressed in #770 but the implementation did not handle all cases. (#781)

## v187 (6/19/2018)

* Prevent apps from deploying with known security vulnerability activated via config (#776)

## v186 (6/12/2018)

* The Ruby buildpack can now detect Rails configuration in a project (#758 #770)

## v185 (5/31/2018)

* The Ruby buildpack bootstrap Ruby version is now 2.5.1. This is not a customer facing feature (#765)

## v184 (5/30/2018)

* Default Ruby version is now 2.4.4 (#734)

## v183 (4/26/2018)

* Support for not yet released heroku-18 stack (#750)

## v182 (4/24/2018)

* Do not warn when `rails runner` cannot be executed (#749)

## v181 (4/23/2018)

* The `active_storage` is not guranteed to be present (#748)

## v180 (4/23/2018)

* Fix case where user environment variables were not being used (#745)

## v179 (4/23/2018)

* Emit warnings for Active Storage (#739)

## v178 (4/17/2018)

* Use S3 directly instead of s3pository for Node downloads (#740)

## v177 (4/10/2018)

* New apps that do not specify a Ruby version now get 2.3.7 (#732)
* Bugfix: `bundle install` output no longer has an extra newline (#735)
* Bugfix: when deploying an application the `ruby` version specified in the Gemfile is available outide of the home directory (#733)

## v176 (3/27/2018)

* Node version upgraded to v8.9.4 (#714)
* Yarn version upgraded to v1.5.1 (#714)
* Fix issue with malformed UTF-8 string parsing (#724)

## v175 (03/21/2018)

* Suggest users encountering a specific sprockets error in specific beta versions to upgrade (#718)
* Log metrics for common failures (#716)

## v174 (02/13/2018)

* Only set JAVA_HOME for Bundler when using JRuby (#649, @jkutner)

## v173 (12/22/2017)

* Remove Bundler shim since Bundler 2.5.0 will not vendor Bundler (#645)

## v172 (12/22/2017)

* updated Ruby 2.5.0 support + Bundler shim (#640)
* Disable bundler version check (#632)
* set JAVA_HOME to absolute path during `bundle install` (#631)

## v170 (10/19/2017)

* Compatiability for Ruby 2.5.0 preview 1 (#628)

## v169 (09/28/2017)

* Yarn version upgraded to v1.0.2

## v168 (08/14/2017)

* Install Node when using either ExecJS _or_ Webpacker (#608)
* Make installs more robust against temporary network issues by retrying failed
  downloads in `LanguagePack::Fetcher#fetch_untar`, which installs Rubies (#585)

## v167 (07/25/2016)

* Update Bundler to 1.15.2 (#602)

## v166 (07/11/2017)

* no changes from v165

## v165 (07/11/2017)

* Set `$JAVA_HOME` for JRuby apps during build (#593)
* Update Node to 6.11.1 (#598)

## v164 (06/21/2017)

* Update Bundler to 1.15.1 (#579)

## v163 (05/22/2017)

* Fix CI rake tasks not running (#571)

## v162 (05/18/2017)

* Disable roubocop warnings for `heroku_clear_tasks` (#567)

## v161 (05/18/2017)

* Ruby apps being run on CI are no longer expected to have Rails commands (#565)

## v160 (05/18/2017)

* `bin/rails test` only gets called in CI for Rails 5+ apps
* support `:sql` (structure) Rails schema for CI (#549)

## v159 (04/24/2017)

*  Blacklist JAVA_OPTS and JAVA_TOOL_OPTIONS during build (#559)

## v158 (04/12/2017)

*  Fix CI issue causing system Ruby to be used (#558)

## v157 (04/11/2017)

* Fix "double ruby rainbow bug" caused by executing two `compile` actions on the same
app (#553 & #555)
* Remove Ruby 1.8.7 compatiability to allow for #555. This version of Ruby has been EOL
for a long time. It is not available on Cedar-14 and Cedar-10 is EOL

## v156 (04/11/2017)

* Update default Ruby version to 2.3.4.

## v155 (03/16/2017)

* Yarn now installed for apps with `webpacker` gem (#547)

## v154 (03/01/2017)

* Postgres database add-on will only be provisioned if app has a postgres driver in the `Gemfile`. (#535)
* Fix regression, where JRuby patchlevel was being pulled from `Gemfile.lock` and used when not appropriate (#536)

## v153 (01/18/2017)

* Fix regression, where defaults would override user env with rake (#528)

## v152 (01/18/2017)

* Remove RAILS_GROUPS=assets from being set in .profile.d (#526)

## v151 (01/16/2017)

* Upgrade to bundler 1.13.7 (#519)
* Vendor Default Ruby to execute the buildpack (#515)
* Heroku CI Support (#516)

## v150 (12/23/2016)

* Allow deployment of pre-release rubies (preview and rc) with Bundler 1.13.6+. This is needed because the patch level is recorded in the gemfile as `-1` since it is not released yet. For example 2.4.0rc1 will show up in a `Gemfile.lock` like this:

```
RUBY VERSION
   ruby 2.4.0p-1
```

## v149 (12/01/2016)

* Guarantee we always show warning when upgrading bundler version.

## v148 (11/17/2016)

* Default Ruby Version is 2.2.6
* Update libyaml to 0.1.7 for [CVE-2014-9130](https://devcenter.heroku.com/changelog-items/1016)

## v147 (11/15/2016)

* Bump bundler to 1.13.6 [Bundler changelog](https://github.com/bundler/bundler/blob/v1.13.6/CHANGELOG.md). Allows for use of Ruby version operators.

## v146 (03/23/2016)

* Warn when `.bundle/config` is checked in (#471)
* Do not cache `.bundle/config` between builds (#471)
* Set WEB_CONCURRENCY for M-Performance dynos using sensible defaults (#474)
* Fix rake task detection in Rails apps actually fails builds (#475)

## v145 (03/08/2016)

* Bump bundler to 1.11.2 [Bundler changelog](https://github.com/bundler/bundler/blob/master/CHANGELOG.md#1112-2015-12-15) (#461)
* Rails 5 Support for logging to STDOUT via environment variable (#460)
* Fail build when rake tasks cannot be detected in a Rails app (#462)

## v144 (02/01/2016)

* Fix default ruby to actually be Ruby 2.2.4 (#456)

## v143 (01/28/2016)

* Change default for new apps to Ruby 2.2.4 (#454)

## v142 (01/14/2016)

* Added pgconfig jar to JDK for JRuby JDBC (#450)
* Let API pick exact postgres plan (#449)
* Follow redirects on `curl` command (#443)
* Check for preinstalled JDK (#434)

## v141 (11/03/2015)

* Support for custom JDK versions in system.properties (#423)
* Fix nodejs buildpack integration (#429)
* Automatic jruby heap setting for IX dynos (#426)
* Warn when RAILS_ENV != production (https://devcenter.heroku.com/articles/deploying-to-a-custom-rails-environment)
* Warn when using asset_sync (https://devcenter.heroku.com/articles/please-do-not-use-asset-sync)

## v140 (9/9/2015)

* JRuby specific ruby error message (#412)

## v139 (8/31/2015)

* Cached asset file should never take precedent over existing file (#402)
* Do not write `database.yml` when using active record >= 4.1 (previously we only detected >= Rails 4.1) (#403)

## v138 (5/19/2015)

* Bump bundler to 1.9.7 [Bundler changelog](https://github.com/bundler/bundler/blob/master/CHANGELOG.md#196-2015-05-02) (#378)

## v137 (5/11/2015)

* Blacklist `JRUBY_OPTS`, use `JRUBY_BUILD_OPTS` to override build `JRUBY_OPTS`.  (#384)
* Revert `--dev` during JRuby build for now. (#384)

## v136 (5/6/2015)

* JRUBY_BUILD_OPTS env var will override any build time jruby opts (#381)

## v135 (5/5/2015)

* Support sprockets 3.0 manifest file naming convention (#367)
* Set `--dev` by default for JRuby builds (but not at runtime). This optimizes the JVM for short process and is ideal for `bundle install` and asset precompiles.
* Cleanup `.git` folders in the bundle directory after `bundle install`.

## v134 (3/1/2015)

* JVM is now available on cedar-14, do not vendor in JVM based on individual gems. If customer needs a specific version they should use multibuildpack with java and ruby buildpacks.
* Set a default value of WEB_CONCURRENCY based on dyno size when `SENSIBLE_DEFAULTS` environment variable is present.
* Run `bundle clean` in the same context as `bundle install` heroku/heroku-buildpack-ruby#347
* Rails 4.2+ apps will have environment variable RAILS_SERVE_STATIC_FILES set to "enabled" by default #349
* Rails 5 apps now work on Heroku #349

## v133 (1/22/2015)

* Bump bundler to 1.7.12 which includes multiple fixes and support for block source declaration (https://github.com/bundler/bundler/blob/1-7-stable/CHANGELOG.md).

## v132 (1/21/2015)

* Support multibuildpack export file (#319)
* Auto set the JVM MAX HEAP based on dyno size for JRuby (#323)
* Use s3 based npmjs servers for node (#336)
* Support system.properties file for specifying JDK in JRuby (#305)
* Fix ruby version parsing to support JRuby 9.0.0.0.pre1 (#339)

## v131 (1/15/2015)

* Revert v130 due to lack of propper messaging around WEB_CONCURRENCY settings.

## v130 (1/15/2015)

* Auto set WEB_CONCURRENCY based on dyno size if not already set.
* Support multibuildpack export file (#319)
* Auto set the JVM MAX HEAP based on dyno size for JRuby (#323)
* Use s3 based npmjs servers for node (#336)
* Support system.properties file for specifying JDK in JRuby (#305)

## v129 (11/6/2014)

* Fix asset caching bug (#300)

## v128 (11/4/2014)

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
