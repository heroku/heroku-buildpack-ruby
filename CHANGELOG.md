# Changelog

## [Unreleased]


## [v267] - 2024-02-28

- Bundler version installation is now based on both major and minor version (https://github.com/heroku/heroku-buildpack-ruby/pull/1428)
- Applications using bundler 2.4+ must now specify a ruby version in the Gemfile.lock or they will receive the default Ruby version (https://github.com/heroku/heroku-buildpack-ruby/pull/1428)

## [v266] - 2024-02-20

- Officially deprecate SENSIBLE_DEFAULTS environment variable (https://github.com/heroku/heroku-buildpack-ruby/pull/1420)

## [v265] - 2024-01-22

- Ruby 3.2.3 is now available

## [v264] - 2023-12-25

- Ruby 3.3.0 is now available

## [v263] - 2023-12-11

- Ruby 3.3.0-rc1 is now available (https://github.com/heroku/heroku-buildpack-ruby/pull/1411)
- Fix BUILDPACK_VENDOR_URL support (https://github.com/heroku/heroku-buildpack-ruby/pull/1406)

## [v262] - 2023-11-08

- Warn when relying on default Node.js or Yarn versions (https://github.com/heroku/heroku-buildpack-ruby/pull/1401)
- Warn when default Node.js or Yarn versions change (https://github.com/heroku/heroku-buildpack-ruby/pull/1401)

## [v261] - 2023-11-02

- JRuby 9.4.5.0 is now available
- JRuby 9.3.13.0 is now available
- Default Node.js version now 20.9.0

## [v260] - 2023-10-23

- JRuby 9.4.4.0 is now available

## [v259] - 2023-10-02

- Ruby 3.3.0-preview2 is now available

## [v258] - 2023-09-26

- No changes

## [v257] - 2023-09-20

- JRuby 9.3.11.0 is now available

## [v256] - 2023-08-04

- Fix Ruby 2.5.7 download on Heroku-20

## [v255] - 2023-07-24

- JRuby 9.4.3.0 is now available
- JRuby 9.4.2.0 is now available

## [v254] - 2023-05-12

- Default Ruby version is now 3.1.4
- Ruby 3.3.0-preview1 is now available

## [v253] - 2023-03-31

- Ruby versions 2.7.8, 3.0.6, 3.1.4, 3.2.2 are now available

## [v252] - 2023-02-08

* Ruby 3.2.1 is now available
* JRuby 9.4.1.0 is now available

## [v251] - 2023-02-03

* Jruby 9.3.10.0 is available

## [v250] - 2022-12-25

* Ruby 3.2.0 is available

## [v249] - 2022-12-16

* Apps with the environment variable `HEROKU_SKIP_DATABASE_PROVISION=1` set will no longer receive a database on the first push to a new Heroku app. This environment variable interface is not standard across other buildpacks and may be deprecated via warnings in the build output and changed in the future.

## [v248] - 2022-12-06

* Ruby 3.2.0-rc1 is available

## [v247] - 2022-12-01

* JRuby 9.3.7.0, 9.3.8.0, 9.3.9.0, 9.4.0.0

## [v246] - 2022-11-29

* Default Node.js version now 16.18.1 (https://github.com/heroku/heroku-buildpack-ruby/pull/1342)
* Default Yarn version now 1.22.19 (https://github.com/heroku/heroku-buildpack-ruby/pull/1342)

## [v245] - 2022-11-16

* Bump Bundler 2 wrapper to 2.3.25 (https://github.com/heroku/heroku-buildpack-ruby/pull/1337)

## [v244] - 2022-07-25

* Default Ruby version is now 3.1.2 (https://github.com/heroku/heroku-buildpack-ruby/pull/1316)

## [v243] - 2022-06-14

* Switch away from deprecated path-based S3 URLs (https://github.com/heroku/heroku-buildpack-ruby/pull/1311)
* Adjust curl retry and connection timeout handling (https://github.com/heroku/heroku-buildpack-ruby/pull/1312)

## [v242] - 2022-06-07

* Ensure `bin/release` exits zero if `tmp/heroku-buildpack-release-step.yml` does not exist (https://github.com/heroku/heroku-buildpack-ruby/pull/1309)
* Bootstrap Ruby version used by the buildpack internals is updated to Ruby 3.1.2 (https://github.com/heroku/heroku-buildpack-ruby/pull/1310)

## [v241] - 2022-06-06

* `bin/release` is re-written in bash, so it supports Heroku-22 (https://github.com/heroku/heroku-buildpack-ruby/pull/1308)
* Download presence check now includes heroku-22 (https://github.com/heroku/heroku-buildpack-ruby/pull/1290)

## [v240] - 2022-04-05

* Add initial support for heroku-22 (https://github.com/heroku/heroku-buildpack-ruby/pull/1289)
* Bundler 2.x is now 2.3.10 (https://github.com/heroku/heroku-buildpack-ruby/pull/1296)

## [v239] - 2022-03-02

* Rollback bundler 2.x change. Bundler 2.x is now back at 2.2.33 (https://github.com/heroku/heroku-buildpack-ruby/pull/1281)

## [v238] - 2022-03-02

* Bundler 2.x is now 2.3.7 (https://github.com/heroku/heroku-buildpack-ruby/pull/1276)

## [v237] - 2022-02-24

* Default Ruby version is now 3.0.3 (https://github.com/heroku/heroku-buildpack-ruby/pull/1270)

## [v236] - 2022-01-04

* Fix deprecated rake tasks for Rails 7 on Heroku CI (https://github.com/heroku/heroku-buildpack-ruby/pull/1257)

## [v235] - 2022-01-03

* Bundler 2.x is now 2.2.33 (https://github.com/heroku/heroku-buildpack-ruby/pull/1248)

## [v234] - 2021-12-16

* Fix YML indentation from v233 (https://github.com/heroku/heroku-buildpack-ruby/pull/1252)

## [v233] - 2021-12-16

* Default node version now 16.13.1, yarn is 1.22.17 (https://github.com/heroku/heroku-buildpack-ruby/pull/1238)
* Default Ruby version is now 2.7.5 (https://github.com/heroku/heroku-buildpack-ruby/pull/1237)
* Remove instrumentation and LPXC logic (https://github.com/heroku/heroku-buildpack-ruby/pull/1229)

## [v232] - 2021-11-09

* Deactivate LPXC (https://github.com/heroku/heroku-buildpack-ruby/pull/1228)

## [v231] - 2021-10-27

* Applications with `package.json` now get `nodejs` installed (https://github.com/heroku/heroku-buildpack-ruby/pull/1212)
* Applications with `yarn.lock` now get `yarn` installed (https://github.com/heroku/heroku-buildpack-ruby/pull/1212)

## [v230] - 2021-10-05

* Default Ruby version is now 2.7.4 (https://github.com/heroku/heroku-buildpack-ruby/pull/1193)

## [v229] - 2021-08-30

* Fix interoperability with other Heroku buildpacks' `$WEB_CONCURRENCY` handling (https://github.com/heroku/heroku-buildpack-ruby/pull/1188)

## [v228] - 2021-06-24

* Bundler 2.x is now 2.2.21 (https://github.com/heroku/heroku-buildpack-ruby/pull/1170)
* Remove support for the Cedar-14 and Heroku-16 stacks (https://github.com/heroku/heroku-buildpack-ruby/pull/1163)

## [v227] - 2021-04-19

* Bundler 2.x is now 2.2.16 (https://github.com/heroku/heroku-buildpack-ruby/pull/1150)

## [v226] - 2021-04-13

* Bundler 2.x is now 2.2.15 (https://github.com/heroku/heroku-buildpack-ruby/pull/1144)

## [v225] - 2021-02-25

* Bundler 2.x is now 2.2.11 (https://github.com/heroku/heroku-buildpack-ruby/pull/1132)

## [v224] - 2021-02-24

* Ruby buildpack now relies on the JVM buildpack to install java for Jruby apps (https://github.com/heroku/heroku-buildpack-ruby/pull/1119)

## [v223] - 2021-01-22

* Fix Gemfile.lock read bug from preventing proper removal of BUNDLED WITH declaration (https://github.com/heroku/heroku-buildpack-ruby/pull/1108)
* Fail detection with a CNB-friendly exit code (https://github.com/heroku/heroku-buildpack-ruby/pull/1111)

## [v222] - 2020-11-02

* CNB support for Heroku-20 (https://github.com/heroku/heroku-buildpack-ruby/pull/1096)

## [v221] - 2020-10-22

* Remove excessive Active Storage warnings (https://github.com/heroku/heroku-buildpack-ruby/pull/1087)
* Add Heroku-20 to the download presence check (https://github.com/heroku/heroku-buildpack-ruby/pull/1093)

## [v220] - 2020-08-07

* BUNDLE_WITHOUT now accommodates values with single spaces (https://github.com/heroku/heroku-buildpack-ruby/pull/1083)

## [v219] - 2020-08-06

* Fix double installation of bundler on CI runs when no test script is specified (https://github.com/heroku/heroku-buildpack-ruby/pull/1073)
* Bundler 2.x is now 2.1.4 (https://github.com/heroku/heroku-buildpack-ruby/pull/1052)
* Persistent bundler config is now being set using the `BUNDLE_*` env vars (https://github.com/heroku/heroku-buildpack-ruby/pull/1039)
* Rake task "assets:clean" will not get called if it does not exist (https://github.com/heroku/heroku-buildpack-ruby/pull/1018)
* CNB: Fix the `gems` layer not being made accessible by subsequent buildpacks (https://github.com/heroku/heroku-buildpack-ruby/pull/1033)

## [v218] - 2020-07-13

* The rake binstub generated from compiling Ruby will no longer be placed in the local `bin/rake` location (https://github.com/heroku/heroku-buildpack-ruby/pull/1031)
* A bug in 2.6.0, 2.6.1, 2.6.3 require a Ruby upgrade, a warning has been added (https://github.com/heroku/heroku-buildpack-ruby/pull/1015)
* The spring library is now disabled by setting the environment variable DISABLE_SPRING=1 (https://github.com/heroku/heroku-buildpack-ruby/pull/1017)
* Warn when a bad "shebang" line in a binstub is detected (https://github.com/heroku/heroku-buildpack-ruby/pull/1014)
* Default node version now 12.16.2, yarn is 1.22.4 (https://github.com/heroku/heroku-buildpack-ruby/pull/986)

 ## [v217] - 2020-07-02

* Gracefully handle unrecognised stacks ([#982](https://github.com/heroku/heroku-buildpack-ruby/pull/982))

## [v216] (rolled back)


## [v215] - 2020-04-09

* Fix bundler cache not being used in CI builds (https://github.com/heroku/heroku-buildpack-ruby/pull/978)

## [v214] - 2020-04-02

* Default Ruby version is now 2.6.6 (https://github.com/heroku/heroku-buildpack-ruby/pull/974)
* Fix regression. PATH value for `yarn` at runtime was relative instead of absolute (https://github.com/heroku/heroku-buildpack-ruby/pull/975)

## [v213] - 2020-04-01

* Fix regression. PATH value for `ruby` at runtime was relative instead of absolute (https://github.com/heroku/heroku-buildpack-ruby/pull/973)

## [v212] - 2020-03-26

* Cloud Native Buildpack support (https://github.com/heroku/heroku-buildpack-ruby/pull/888)

## [v211] - 2020-03-12

* Fix issue where the wrong version of bundler is used on CI apps (https://github.com/heroku/heroku-buildpack-ruby/pull/961)
* Remove libpq external dependency (https://github.com/heroku/heroku-buildpack-ruby/pull/959)

## [v210] - 2020-03-06

* Fix version download error warning inversion logic (https://github.com/heroku/heroku-buildpack-ruby/pull/958)

## [v209] - 2020-03-05

* Fix bug in version download error message logic (https://github.com/heroku/heroku-buildpack-ruby/pull/957)

## [v208] - 2020-03-04

* Improve Ruby version download error messages (https://github.com/heroku/heroku-buildpack-ruby/pull/953)
* Update default Ruby version to 2.6.5 (https://github.com/heroku/heroku-buildpack-ruby/pull/947)

## [v207] - 2019-12-16

* Vendor in libpq 5.12.1 for Heroku-18 (https://github.com/heroku/heroku-buildpack-ruby/pull/936)
* Remove possibilities of false exceptions being raised by removing `BUNDLED WITH` from the `Gemfile.lock` (https://github.com/heroku/heroku-buildpack-ruby/pull/928)

## [v206] - 2019-10-15

* Default Ruby version for new apps is now 2.5.7 (https://github.com/heroku/heroku-buildpack-ruby/pull/926)
* Using old and EOL versions of Ruby now generate warnings (https://github.com/heroku/heroku-buildpack-ruby/pull/864)

## [v205] - 2019-09-24

* Update bundler 1.x to 1.17.3 (https://github.com/heroku/heroku-buildpack-ruby/pull/845)
* Default `MALLOC_ARENA_MAX=2` for new applications (https://github.com/heroku/heroku-buildpack-ruby/pull/752)

## [v204] - 2019-09-12

* Default Ruby version for new apps is now 2.5.6 (https://github.com/heroku/heroku-buildpack-ruby/pull/919)
* Ensure that old binstubs are removed before new ones are generated (https://github.com/heroku/heroku-buildpack-ruby/pull/914)
* Fix windows Gemfile.lock BUNDLED WITH support (https://github.com/heroku/heroku-buildpack-ruby/pull/898)

## [v203] - 2019-08-20

* Make sure Rails 6 apps have a `tmp/pids` folder so they can boot (https://github.com/heroku/heroku-buildpack-ruby/pull/909)

## [v202] - 2019-08-20

* Add support class for Rails 6 (https://github.com/heroku/heroku-buildpack-ruby/pull/908)

## [v201] - 2019-06-23

* Set memory default for Node builds (https://github.com/heroku/heroku-buildpack-ruby/pull/861)
* Default Ruby version is now 2.5.5, was previously 2.5.3 (https://github.com/heroku/heroku-buildpack-ruby/pull/863)
* Default Node version is now 10.15.3 and default Yarn version is now 1.16.0 (https://github.com/heroku/heroku-buildpack-ruby/pull/884)
* Bundler 2 now uses 2.0.2 (https://github.com/heroku/heroku-buildpack-ruby/pull/894)

## [v200] - 2019-03-07

* Fix: Environment variables not being exported for other buildpacks in CI (https://github.com/heroku/heroku-buildpack-ruby/pull/858)
* Ignore invalid byte encodings when detecting rails config (https://github.com/heroku/heroku-buildpack-ruby/pull/854)

## v199 - 2019-02-19

* Add support for arbitrary Bundler major versions, most notably bundler 2 (https://github.com/heroku/heroku-buildpack-ruby/pull/850)

## v198 - 2019-01-17

* Rev-default Ruby version to be the latest patch release of last years Ruby version 2.5.3 (https://github.com/heroku/heroku-buildpack-ruby/pull/846)
* Allow apps to enable `RUBYOPT=--jit` (https://github.com/heroku/heroku-buildpack-ruby/pull/848)

## v197 - 2018-12-18

* Upgrade node version (https://github.com/heroku/heroku-buildpack-ruby/pull/831)
* Upgrade yarn version (https://github.com/heroku/heroku-buildpack-ruby/pull/832)

## v196 - 2018-10-31

* Delete the sprockets temp directory for a smaller runtime slug if they are not building assets at runtime (https://github.com/heroku/heroku-buildpack-ruby/pull/812)

## v195 - 2018-10-18

* Default Ruby version is now 2.4.5 (https://github.com/heroku/heroku-buildpack-ruby/pull/821)

## v194 - 2018-10-16

* Do not add the `jobs:work` command if an app does not have that rake task available (https://github.com/heroku/heroku-buildpack-ruby/pull/810)

## v193 - 2018-09-14

* Fix link (https://github.com/heroku/heroku-buildpack-ruby/pull/811)

## v192 - 2018-09-14

* Add error messages when using unsupported Ruby versions on the Heroku-18 stack (https://github.com/heroku/heroku-buildpack-ruby/pull/809)

## v191 - 2018-08-23

* Warn when `config.action_dispatch.x_sendfile_header` is set but apache and nginx are not being used (https://github.com/heroku/heroku-buildpack-ruby/pull/795)

## v190 - 2018-07-24

* Support TAP output for Heroku CI (https://github.com/heroku/heroku-buildpack-ruby/pull/790).

## v189 - 2018-07-10

* Colorize build failures and warnings. (https://github.com/heroku/heroku-buildpack-ruby/pull/788)

## v188 - 2018-06-26

* Fix rails config detect timeout. Addresses the process deadlock when detecting rails config that contains an infinite task. This was originally addressed in #770 but the implementation did not handle all cases. (#781)

## v187 - 2018-06-19

* Prevent apps from deploying with known security vulnerability activated via config (#776)

## v186 - 2018-06-12

* The Ruby buildpack can now detect Rails configuration in a project (#758 #770)

## v185 - 2018-05-31

* The Ruby buildpack bootstrap Ruby version is now 2.5.1. This is not a customer facing feature (#765)

## v184 - 2018-05-30

* Default Ruby version is now 2.4.4 (#734)

## v183 - 2018-04-26

* Support for not yet released heroku-18 stack (#750)

## v182 - 2018-04-24

* Do not warn when `rails runner` cannot be executed (#749)

## v181 - 2018-04-23

* The `active_storage` is not guaranteed to be present (#748)

## v180 - 2018-04-23

* Fix case where user environment variables were not being used (#745)

## v179 - 2018-04-23

* Emit warnings for Active Storage (#739)

## v178 - 2018-04-17

* Use S3 directly instead of s3pository for Node downloads (#740)

## v177 - 2018-04-10

* New apps that do not specify a Ruby version now get 2.3.7 (#732)
* Bugfix: `bundle install` output no longer has an extra newline (#735)
* Bugfix: when deploying an application the `ruby` version specified in the Gemfile is available outside of the home directory (#733)

## v176 - 2018-03-27

* Node version upgraded to v8.9.4 (#714)
* Yarn version upgraded to v1.5.1 (#714)
* Fix issue with malformed UTF-8 string parsing (#724)

## v175 - 2018-03-21

* Suggest users encountering a specific sprockets error in specific beta versions to upgrade (#718)
* Log metrics for common failures (#716)

## v174 - 2018-02-13

* Only set JAVA_HOME for Bundler when using JRuby (#649, @jkutner)

## v173 - 2017-12-22

* Remove Bundler shim since Bundler 2.5.0 will not vendor Bundler (#645)

## v172 - 2017-12-22

* updated Ruby 2.5.0 support + Bundler shim (#640)
* Disable bundler version check (#632)
* set JAVA_HOME to absolute path during `bundle install` (#631)

## v170 - 2017-10-19

* Compatibility for Ruby 2.5.0 preview 1 (#628)

## v169 - 2017-09-28

* Yarn version upgraded to v1.0.2

## v168 - 2017-08-14

* Install Node when using either ExecJS _or_ Webpacker (#608)
* Make installs more robust against temporary network issues by retrying failed
  downloads in `LanguagePack::Fetcher#fetch_untar`, which installs Rubies (#585)

## v167 - 2016-07-25

* Update Bundler to 1.15.2 (#602)

## v166 - 2017-07-11

* no changes from v165

## v165 - 2017-07-11

* Set `$JAVA_HOME` for JRuby apps during build (#593)
* Update Node to 6.11.1 (#598)

## v164 - 2017-06-21

* Update Bundler to 1.15.1 (#579)

## v163 - 2017-05-22

* Fix CI rake tasks not running (#571)

## v162 - 2017-05-18

* Disable RuboCop warnings for `heroku_clear_tasks` (#567)

## v161 - 2017-05-18

* Ruby apps being run on CI are no longer expected to have Rails commands (#565)

## v160 - 2017-05-18

* `bin/rails test` only gets called in CI for Rails 5+ apps
* support `:sql` (structure) Rails schema for CI (#549)

## v159 - 2017-04-24

*  Blacklist JAVA_OPTS and JAVA_TOOL_OPTIONS during build (#559)

## v158 - 2017-04-12

*  Fix CI issue causing system Ruby to be used (#558)

## v157 - 2017-04-11

* Fix "double ruby rainbow bug" caused by executing two `compile` actions on the same
app (#553 & #555)
* Remove Ruby 1.8.7 compatibility to allow for #555. This version of Ruby has been EOL
for a long time. It is not available on Cedar-14 and Cedar-10 is EOL

## v156 - 2017-04-11

* Update default Ruby version to 2.3.4.

## v155 - 2017-03-16

* Yarn now installed for apps with `webpacker` gem (#547)

## v154 - 2017-03-01

* Postgres database add-on will only be provisioned if app has a postgres driver in the `Gemfile`. (#535)
* Fix regression, where JRuby patchlevel was being pulled from `Gemfile.lock` and used when not appropriate (#536)

## v153 - 2017-01-18

* Fix regression, where defaults would override user env with rake (#528)

## v152 - 2017-01-18

* Remove RAILS_GROUPS=assets from being set in .profile.d (#526)

## v151 - 2017-01-16

* Upgrade to bundler 1.13.7 (#519)
* Vendor Default Ruby to execute the buildpack (#515)
* Heroku CI Support (#516)

## v150 - 2016-12-23

* Allow deployment of pre-release rubies (preview and rc) with Bundler 1.13.6+. This is needed because the patch level is recorded in the gemfile as `-1` since it is not released yet. For example 2.4.0rc1 will show up in a `Gemfile.lock` like this:

```
RUBY VERSION
   ruby 2.4.0p-1
```

## v149 - 2016-12-01

* Guarantee we always show warning when upgrading bundler version.

## v148 - 2016-11-17

* Default Ruby Version is 2.2.6
* Update libyaml to 0.1.7 for [CVE-2014-9130](https://devcenter.heroku.com/changelog-items/1016)

## v147 - 2016-11-15

* Bump bundler to 1.13.6 [Bundler changelog](https://github.com/bundler/bundler/blob/v1.13.6/CHANGELOG.md). Allows for use of Ruby version operators.

## v146 - 2016-03-23

* Warn when `.bundle/config` is checked in (#471)
* Do not cache `.bundle/config` between builds (#471)
* Set WEB_CONCURRENCY for M-Performance dynos using sensible defaults (#474)
* Fix rake task detection in Rails apps actually fails builds (#475)

## v145 - 2016-03-08

* Bump bundler to 1.11.2 [Bundler changelog](https://github.com/bundler/bundler/blob/master/CHANGELOG.md#1112-2015-12-15) (#461)
* Rails 5 Support for logging to STDOUT via environment variable (#460)
* Fail build when rake tasks cannot be detected in a Rails app (#462)

## v144 - 2016-02-01

* Fix default ruby to actually be Ruby 2.2.4 (#456)

## v143 - 2016-01-28

* Change default for new apps to Ruby 2.2.4 (#454)

## v142 - 2016-01-14

* Added pgconfig jar to JDK for JRuby JDBC (#450)
* Let API pick exact postgres plan (#449)
* Follow redirects on `curl` command (#443)
* Check for preinstalled JDK (#434)

## v141 - 2015-11-03

* Support for custom JDK versions in system.properties (#423)
* Fix nodejs buildpack integration (#429)
* Automatic jruby heap setting for IX dynos (#426)
* Warn when RAILS_ENV != production (https://devcenter.heroku.com/articles/deploying-to-a-custom-rails-environment)
* Warn when using asset_sync (https://devcenter.heroku.com/articles/please-do-not-use-asset-sync)

## v140 - 2015-09-09

* JRuby specific ruby error message (#412)

## v139 - 2015-08-31

* Cached asset file should never take precedent over existing file (#402)
* Do not write `database.yml` when using active record >= 4.1 (previously we only detected >= Rails 4.1) (#403)

## v138 - 2015-05-19

* Bump bundler to 1.9.7 [Bundler changelog](https://github.com/bundler/bundler/blob/master/CHANGELOG.md#196-2015-05-02) (#378)

## v137 - 2015-05-11

* Blacklist `JRUBY_OPTS`, use `JRUBY_BUILD_OPTS` to override build `JRUBY_OPTS`.  (#384)
* Revert `--dev` during JRuby build for now. (#384)

## v136 - 2015-05-06

* JRUBY_BUILD_OPTS env var will override any build time jruby opts (#381)

## v135 - 2015-05-05

* Support sprockets 3.0 manifest file naming convention (#367)
* Set `--dev` by default for JRuby builds (but not at runtime). This optimizes the JVM for short process and is ideal for `bundle install` and asset precompiles.
* Cleanup `.git` folders in the bundle directory after `bundle install`.

## v134 - 2015-03-01

* JVM is now available on cedar-14, do not vendor in JVM based on individual gems. If customer needs a specific version they should use multibuildpack with java and ruby buildpacks.
* Set a default value of WEB_CONCURRENCY based on dyno size when `SENSIBLE_DEFAULTS` environment variable is present.
* Run `bundle clean` in the same context as `bundle install` heroku/heroku-buildpack-ruby#347
* Rails 4.2+ apps will have environment variable RAILS_SERVE_STATIC_FILES set to "enabled" by default #349
* Rails 5 apps now work on Heroku #349

## v133 - 2015-01-22

* Bump bundler to 1.7.12 which includes multiple fixes and support for block source declaration (https://github.com/bundler/bundler/blob/1-7-stable/CHANGELOG.md).

## v132 - 2015-01-21

* Support multibuildpack export file (#319)
* Auto set the JVM MAX HEAP based on dyno size for JRuby (#323)
* Use s3 based npmjs servers for node (#336)
* Support system.properties file for specifying JDK in JRuby (#305)
* Fix ruby version parsing to support JRuby 9.0.0.0.pre1 (#339)

## v131 - 2015-01-15

* Revert v130 due to lack of proper messaging around WEB_CONCURRENCY settings.

## v130 - 2015-01-15

* Auto set WEB_CONCURRENCY based on dyno size if not already set.
* Support multibuildpack export file (#319)
* Auto set the JVM MAX HEAP based on dyno size for JRuby (#323)
* Use s3 based npmjs servers for node (#336)
* Support system.properties file for specifying JDK in JRuby (#305)

## v129 - 2014-11-06

* Fix asset caching bug (#300)

## v128 - 2014-11-04

* Better cedar14 Ruby install error message

## v127 - 2014-09-18

* rbx is now stack aware

## v126 - 2014-08-04

* fix bundler cache clearing on ruby version change
* vendor the jvm when yui-compressor is detected

## v125 - 2014-08-01

* bump to node 0.10.30 on cedar-14

## v124 - 2014-08-01

* use node 0.10.29 on cedar-14
* properly use vendored jvm, so not to be dependent on java on the stack image

## v123 - 2014-07-25

* fix permission denied edge cases when copying the bundler cache with minitest

## v122 - 2014-07-25

* handle bundler cache for stack changes on existing apps

## v121 - 2014-06-30

* on new apps, source default envs instead of replacing them
* support different stacks for new apps

## v120 - 2014-06-16

* Bump bundler to 1.6.3 which includes improved dependency resolver

## v119 - 2014-05-09

* Temporarily disable default ruby cache

## v118 - 2014-05-06

* Ruby version detection now loads user environment variables

## v117 - 2014-04-14

Features:


Bugfixes:

* fix anvil use case of multibuildpack with node


## v116 - 2014-04-10

Features:


Bugfixes:

* Revert back to Bundler 1.5.2


## v115 - 2014-04-09

Features:


Bugfixes:

* Add default process types to all apps deployed regardless of `Procfile`

## v114 - 2014-04-09

Features:

* Bundler 1.6.1
* Warn when not using a Procfile (looking at you webrick)

Bugfixes:


## v113 - 2014-04-08

Features:

* use heroku-buildpack-nodejs's node binary
* `CURL_CONNECT_TIMEOUT` and `CURL_TIMEOUT` are configurable as ENV vars

Bugfixes:

* Don't double print "Running: rake assets:precompile" on Ruby apps


## v112 - 2014-03-27

Features:


Bugfixes:

* compile psych with libyaml 0.1.6 for CVE-2014-2525

## v111 - 2014-03-20

Features:


Bugfixes:

* spelling


## v110 - 2014-03-20

Features:

* Better message when running `assets:precompile` without a database

Bugfixes:

## v108 - 2014-02-27

Features:

* parse Bundler patchlevel option

Bugfixes:

* don't let users step on themselves by replacing `env` in `$PATH`

## v107 - 2014-02-26

Features:

Bugfixes:

* more shell escaping bug fixes


## v105

Rollbacked to v103


## v104 - 2014-02-26

Features:

Bugfixes:

* fix bugs in shell escaping (#231)


## v103 - 2014-02-18

Features:

* Rails 4.1.0 Support. Stop writing database.yml and support for secrets.yml by generating SECRET_KEY_BASE for users.

Bugfixes:


## v102 - 2014-02-06

Features:

Bugfixes:

* use blacklist of env vars, so users can't break the build process


## v101 - 2014-02-05

Features:

Bugfixes:

* fix rake detection when DATABASE_URL is not present
* support BUNDLE_WITHOUT when using ponies
* quote ponies env vars, so build doesn't break


## v100 - 2014-02-04

Features:

Bugfixes:

* compile psych with libyaml 0.1.5 for CVE-2013-6393

## v99 - 2014-02-04

Features:

* Noop

Bugfixes:


## v98 - 2014-01-30

Features:

Bugfixes:

* Use vendored JDK binary during build


## v97 - 2014-01-30

Features:

Bugfixes:

* Actually finalize method rename to `install_bundler_in_app`


## v96 - 2014-01-29

Features:

Bugfixes:

* Finalize method rename to `install_bundler_in_app`

## v95

Rollback to v93

## v94 - 2014-01-29

Features:

Bugfixes:

* Fixed `uninitialized constant Rake::DSL` error when running rake tasks on Ruby 1.9.2

## v93 - 2014-01-28

Features:

* buildpack-env-arg (ponies) support

Bugfixes:

## v92 - 2014-01-27

Features:

Bugfixes:

* Only display rake error messages if a `Rakefile` exists
* when detecting for ruby version, don't use stderr messages

## v91 - 2014-01-16

Features:

* Parallel gem installation with bundler 1.5.2

Bugfixes:


## v90 - 2014-01-09

Features:

* Rollback v89 due to bug in bundler 1.5.1

Bugfixes:

## v89 - 2014-01-09

Features:

* Use most recent version of bundler with support for parallel Gem installation

Bugfixes:

## v86 - 2013-12-11

Features:

Bugfixes:

* Windows warnings will now display before bundle install, this prevents an un-resolvable `Gemfile` from erroring which previously prevented the warning roll up from being shown. When this happened the developer did not see that we are clearing the `Gemfile.lock` from the git repository when bundled on a windows machine.
* Checks for `public/assets/manifest*.json` and `public/assets/manifest.yml` will now come before Rake task detection introduced in v85.

## v85 - 2013-12-05

Features:


Bugfixes:

* Any errors in a Rakefile will now be explicitly shown as such instead of hidden in a `assets:precompile` task detection failure (#171)
* Now using correct default "hobby" database #179

## v84 - 2013-11-06

Features:

* Any Ruby app with a rake `assets:precompile` task present that does not run successfully will now fail. This matches the current behavior of Rails 3 and 4 deploys.


Bugfixes:

* Fix default gem cache

## v83 - 2013-10-29

Features:

* RubyVersion extracted into its own class
* Release no longer requires language_pack
* Detect no longer requires language_pack
* Downloads with curl now retry on failed connections, pass exit status appropriately

Bugfixes:

* Errors in Gemfiles will no longer show up as bad ruby versions #36
* Fix warning warning libjffi-1.2.so on < JRuby 1.7.3

## v82 - 2013-10-28

Bugfixes:

* Rails 3 deploys that do not successfully run `assets:precompile` will now fail.

## v81 - 2013-10-15

Features:

* add Default Bundler Cache for new Ruby 2.0.0 apps
* use Virginia S3 bucket instead of Cloudfront

## v80 - 2013-09-23

Features:

* Cache 50mb of Rails 4 intermediate cache
* Support for Ruby 2.1.0

Bugfixes:

* Disable invoke dynamic on JRuby by default until JDK stabilizes it

## v79 - 2013-09-03

Bugfixes:

* Remove LPXC debug output when `DEBUG` env var is set (#141)
* Symlink ruby.exe, so Rails 4 bins work for Windows (#139)

## v78 - 2013-08-28

Features:

* Don't add plugins if already gems

Bugfixes:

* Fix issue #127 Race condition with LPXC

## v77 - 2013-08-05

Features:

* Force nokogiri to compile with system libs

## v76 - 2013-07-29

Bugfixes:

* fix request_id for instrumentation to follow standard

## v75 - 2013-07-29

Features:

* add request_id to instrumentation
* switchover to rubinius hosted rbx binaries

Bugfixes:

* OpenJDK version was rolled back, stop special casing JRuby 1.7.3.

## v74 - 2013-07-24

Bugfixes:

* Lock JRuby 1.7.3 and lower to older version of JDK due to <https://github.com/jruby/jruby/issues/626>

## v73 - 2013-07-23

* Revert to v69 due to asset:precompile bugs

## v72 - 2013-07-23

Bugfixes:

* Fix rake task detection for Rails 3 (@hynkle, #118)

## v71 - 2013-07-18

* Revert to v69 due to asset:precompile bugs

## v70 - 2013-07-18

Bugfixes:

* Don't silently fail rake task checks (@gabrielg, #34)

## v69 - 2013-07-16

Bugfixes:

* Add spacing to end of instrumentation

## v68 - 2013-07-16

Features:

* Log buildpack name and entering rails3/4 compile

## v67 - 2013-07-10

Features:

* Fetcher uses CDN if available
* Add buildpack_version to the instrumentation output

Bugfixes:

* Don't print DEBUG messages for lxpc when env var is present
* Fix ruby gemfile warning line for JRuby

## v66 - 2013-07-09

Bugfixes:

* Include logtoken properly

## v65 - 2013-07-09

Features:

* Instrument timing infrastructure for the buildpack

Bugfixes:

* Fix DATABASE_URL to use jdbc-postgres for JRuby (@jkrall, #116)

## v64 - 2013-06-19

Features:

* only download one copy of bundler per process (@dpiddy, #69)
* roll up all warnings for end of push output
* write database.yml for Rails 4

Bugfixes:

* fix sqlite3 error messaging detection

## v63 - 2013-06-17

Features:

* Lock default ruby if default ruby is used
* Change default ruby to 2.0.0
* Stop using the stack image ruby and always vendor ruby

## v62 - 2013-05-21

Bugfixes:

* Correctly detect asset manifest files in Rails 4
* Fix jruby 1.8.7 bundler/psych require bug

## v61 - 2013-04-18

Features:

* Start caching the rubygems version used.

Bugfixes:

* Rebuild bundler cache if rubygems 2 is detected. Bugfixes in later rubygems.

## v60 - 2013-04-17

Security:

* Disable Java RMI Remote Classloading for CVE-2013-1537, <https://bugzilla.redhat.com/show_bug.cgi?id=952387>

## v59 - 2013-04-04

Bugfixes:

* Change JVM S3 bucket

## v58 - 2013-03-19

Bugfixes:

* Fix ruby 1.8.7 not being able to compile native extensions

## v57 - 2013-03-18

Bugfixes:

* Fix git gemspec bug in bundler

## v56 - 2013-03-11

Bugfixes:

* Upgrade bundler to 1.3.2 to fix --dry-clean/Would have removed bug in bundle clean, part 2.

## v55 - 2013-03-07

Bugfixes:

* Revert back to Bundler 1.3.0.pre.5, see https://gist.github.com/mattonrails/e063caf86962995e7ba0

## v54 - 2013-03-07

Bugfixes:

* Upgrade bundler to 1.3.2 to fix --dry-clean/Would have removed bug in bundle clean

## v53 - 2013-03-06

Bugfixes:

* bin/detect for Rails 3 and 4 will use railties for detection vs the rails gem
* bin/detect does not error out when Gemfile + Gemfile.lock are missing

## v52 - 2013-02-25

Bugfixes:

* Revert back to 1.3.0.pre.5 due to bundler warnings

## v51 - 2013-02-25

Features:

* Initial Rails 4 beta support
* Upgrade bundler to 1.3.0

Bugfixes:

* Better buildpack detection through Gemfile.lock gems

## v50 - 2013-01-31

Features:

* Restore ruby deploys back to normal

## v49 - 2013-01-30

Features:

* Re-enable ruby deploys for apps just using the heroku cache
* Display ruby version change when busting the cache

## v48 - 2013-01-30

Features:

* Update deploy error message copy to link to status incident.

## v47 - 2013-01-30

Features:

* Disable ruby deploys due to rubygems.org compromise

## v46 - 2013-01-10

Features:

* Upgrade Bundler to 1.3.0.pre.5
* bundler binstubs now go in vendor/bundle/bin

## v45 - 2012-12-14

Features:

* Stop setting env vars in bin/release now that login-shell is released
* Enable Invoke Dynamic on JRuby by default
* GEM_PATH is now updated on each push

## v44 - 2012-12-14

Faulty Release

## v43 - 2012-12-13

Features:

* Upgrade Bundler to 1.3.0.pre.2

## v42 - 2012-11-26

Features:

* Upgrade Bundler to 1.2.2 to fix Ruby 2.0.0/YAML issues

## v41 - 2012-11-01

Features:

* Enable ruby 2.0.0 support for testing

## v40 - 2012-10-14

Features:

* Cache version of the buildpack we used to deploy
* Purge cache when v38 is detected

## v39 - 2012-10-14

Bugfixes:

* Don't display cache clearing message for new apps
* Actually clear bundler cache on ruby version change

## v38 - 2012-10-14

Bugfixes:

* Stop bundle cache from continually growing

## v37 - 2012-10-12

Bugfixes:

* Remove temporary workaround from v36.
* Clear bundler cache upon Ruby version change

## v36 - 2012-10-12

Bugfixes:

* Always clear the cache for ruby 1.9.3 as a temporary workaround due to the security upgrade

## v35 - 2012-09-19

Features:

* Upgrade to Bundler 1.2.1
* Display bundle clean output
* More resilient to rubygems.org API outages

Bugfixes:

* `bundle clean` works again

## v34 - 2012-08-30

Features:

* Upgrade to Bundler 1.2.0

## v33 - 2012-08-09

Features:

* Upgrade to Bundler 1.2.0.rc.2
* vendor JDK7 for JRuby, but disable invoke dynamic

## v29 - 2012-07-19

Features:

* support .profile.d/ruby.sh
* sync stdout so that the buildpack streams even in non-interactive shells
* Upgrade to Bundler 1.2.0.rc

## v28 - 2012-07-16

Features:

* Vendor OpenJDK6 into slug when using JRuby
* ruby version support for ruby 1.8.7 via bundler's ruby DSL

Bugfixes:

* sqlite3 error gets displayed again

## v27 - 2012-06-14

Bugfixes:

* Remove `vendor/bundle` message only appears when dir actually exists

## v26 - 2012-06-14

Features:

* print message when assets:precompile finishes successfully
* Remove `vendor/bundle` if user commits it to their git repo.

## v25 - 2012-06-12

Features:

* support "ruby-xxx-jruby-yyy" for jruby detection packages

## v24 - 2012-06-07

Features:

* removes bundler cache in the slug, to minimize slug size (@stevenh512, #16)
* optimize push time with caching

## v23 - 2012-05-08

Bugfixes:

* fix ruby version bug with "fatal:-Not-a-git-repository"

## v22 - 2012-05-07

Features:

* bundler 1.2.0.pre
* ruby version support for ruby 1.9.2/1.9.3 via bundler's ruby DSL

Deprecation:

* ENV['RUBY_VERSION'] in favor of bundler's ruby DSL

## v21 - 2012-03-21

Features:

* bundler 1.1.2

## v20 - 2012-03-12

Features:

* bundler 1.1.0 \o/

## v19 - 2012-01-25

Bugfixes:

* fix native extension building for rbx 2.0.0dev

## v18 - 2012-01-18

Features:

* JRuby support
* rbx 2.0.0dev support

Bugfixes:

* force db password to be a string in the yaml file

## v17 - 2011-12-29

Features:

* bundler 1.1.rc.7

## v16 - 2011-12-29

Features:

* pass DATABASE_URL to rails 3.1 assets:precompile rake task detection

## v15 - 2011-12-27

Features:

* bundler 1.1.rc.6

## v14 - 2011-12-22

Bugfixes:

* stop freedom patching syck in ruby 1.9.3+

## v13 - 2011-12-15

Features:

* bundler 1.1.rc.5

## v12 - 2011-12-13

Bugfixes:

* syck workaround for yaml/psych issues

## v11 - 2011-12-12

Features:

* bundler 1.1.rc.3

## v10 - 2011-11-23

Features:

* bundler binstubs
* dynamic slug_vendor_base detection

Bugfixes:

* don't show sqlite3 error if it's in a bundle without group on failed bundle install

## v9 - 2011-11-14

Features:

* rbx 1.2.4 support
* print out RUBY_VERSION being used

Bugfixes:

* don't leave behind ruby_versions.yml

## v8 - 2011-11-08

Features:

* use vm as part of RUBY_VERSION

## v7 - 2011-11-08

Features:

* ruby 1.9.3 support
* specify ruby versions using RUBY_VERSION build var

Bugfixes:

* move "bin/" to the front of the PATH, so apps can override existing bins

## v6 - 2011-11-02

Features:

* add sqlite3 warning when detected on bundle install error

Bugfixes:

* Change gem detection to use lockfile parser
* use `$RACK_ENV` when thin is detected for rack apps

[unreleased]: https://github.com/heroku/heroku-buildpack-ruby/compare/v267...main
[v267]: https://github.com/heroku/heroku-buildpack-ruby/compare/v266...v267
[v266]: https://github.com/heroku/heroku-buildpack-ruby/compare/v265...v266
[v265]: https://github.com/heroku/heroku-buildpack-ruby/compare/v264...v265
[v264]: https://github.com/heroku/heroku-buildpack-ruby/compare/v263...v264
[v263]: https://github.com/heroku/heroku-buildpack-ruby/compare/v262...v263
[v262]: https://github.com/heroku/heroku-buildpack-ruby/compare/v261...v262
[v261]: https://github.com/heroku/heroku-buildpack-ruby/compare/v260...v261
[v260]: https://github.com/heroku/heroku-buildpack-ruby/compare/v259...v260
[v259]: https://github.com/heroku/heroku-buildpack-ruby/compare/v258...v259
[v258]: https://github.com/heroku/heroku-buildpack-ruby/compare/v257...v258
[v257]: https://github.com/heroku/heroku-buildpack-ruby/compare/v256...v257
[v256]: https://github.com/heroku/heroku-buildpack-ruby/compare/v255...v256
[v255]: https://github.com/heroku/heroku-buildpack-ruby/compare/v254...v255
[v254]: https://github.com/heroku/heroku-buildpack-ruby/compare/v253...v254
[v253]: https://github.com/heroku/heroku-buildpack-ruby/compare/v252...v253
[v252]: https://github.com/heroku/heroku-buildpack-ruby/compare/v251...v252
[v251]: https://github.com/heroku/heroku-buildpack-ruby/compare/v250...v251
[v250]: https://github.com/heroku/heroku-buildpack-ruby/compare/v249...v250
[v249]: https://github.com/heroku/heroku-buildpack-ruby/compare/v248...v249
[v248]: https://github.com/heroku/heroku-buildpack-ruby/compare/v247...v248
[v247]: https://github.com/heroku/heroku-buildpack-ruby/compare/v246...v247
[v246]: https://github.com/heroku/heroku-buildpack-ruby/compare/v245...v246
[v245]: https://github.com/heroku/heroku-buildpack-ruby/compare/v244...v245
[v244]: https://github.com/heroku/heroku-buildpack-ruby/compare/v243...v244
[v243]: https://github.com/heroku/heroku-buildpack-ruby/compare/v242...v243
[v242]: https://github.com/heroku/heroku-buildpack-ruby/compare/v241...v242
[v241]: https://github.com/heroku/heroku-buildpack-ruby/compare/v240...v241
[v240]: https://github.com/heroku/heroku-buildpack-ruby/compare/v239...v240
[v239]: https://github.com/heroku/heroku-buildpack-ruby/compare/v238...v239
[v238]: https://github.com/heroku/heroku-buildpack-ruby/compare/v237...v238
[v237]: https://github.com/heroku/heroku-buildpack-ruby/compare/v236...v237
[v236]: https://github.com/heroku/heroku-buildpack-ruby/compare/v235...v236
[v235]: https://github.com/heroku/heroku-buildpack-ruby/compare/v234...v235
[v234]: https://github.com/heroku/heroku-buildpack-ruby/compare/v233...v234
[v233]: https://github.com/heroku/heroku-buildpack-ruby/compare/v232...v233
[v232]: https://github.com/heroku/heroku-buildpack-ruby/compare/v231...v232
[v231]: https://github.com/heroku/heroku-buildpack-ruby/compare/v230...v231
[v230]: https://github.com/heroku/heroku-buildpack-ruby/compare/v229...v230
[v229]: https://github.com/heroku/heroku-buildpack-ruby/compare/v228...v229
[v228]: https://github.com/heroku/heroku-buildpack-ruby/compare/v227...v228
[v227]: https://github.com/heroku/heroku-buildpack-ruby/compare/v226...v227
[v226]: https://github.com/heroku/heroku-buildpack-ruby/compare/v225...v226
[v225]: https://github.com/heroku/heroku-buildpack-ruby/compare/v224...v225
[v224]: https://github.com/heroku/heroku-buildpack-ruby/compare/v223...v224
[v223]: https://github.com/heroku/heroku-buildpack-ruby/compare/v222...v223
[v222]: https://github.com/heroku/heroku-buildpack-ruby/compare/v221...v222
[v221]: https://github.com/heroku/heroku-buildpack-ruby/compare/v220...v221
[v220]: https://github.com/heroku/heroku-buildpack-ruby/compare/v219...v220
[v219]: https://github.com/heroku/heroku-buildpack-ruby/compare/v218...v219
[v218]: https://github.com/heroku/heroku-buildpack-ruby/compare/v217...v218
[v217]: https://github.com/heroku/heroku-buildpack-ruby/compare/v216...v217
[v216]: https://github.com/heroku/heroku-buildpack-ruby/compare/v215...v216
[v215]: https://github.com/heroku/heroku-buildpack-ruby/compare/v214...v215
[v214]: https://github.com/heroku/heroku-buildpack-ruby/compare/v213...v214
[v213]: https://github.com/heroku/heroku-buildpack-ruby/compare/v212...v213
[v212]: https://github.com/heroku/heroku-buildpack-ruby/compare/v211...v212
[v211]: https://github.com/heroku/heroku-buildpack-ruby/compare/v210...v211
[v210]: https://github.com/heroku/heroku-buildpack-ruby/compare/v209...v210
[v209]: https://github.com/heroku/heroku-buildpack-ruby/compare/v208...v209
[v208]: https://github.com/heroku/heroku-buildpack-ruby/compare/v207...v208
[v207]: https://github.com/heroku/heroku-buildpack-ruby/compare/v206...v207
[v206]: https://github.com/heroku/heroku-buildpack-ruby/compare/v205...v206
[v205]: https://github.com/heroku/heroku-buildpack-ruby/compare/v204...v205
[v204]: https://github.com/heroku/heroku-buildpack-ruby/compare/v203...v204
[v203]: https://github.com/heroku/heroku-buildpack-ruby/compare/v202...v203
[v202]: https://github.com/heroku/heroku-buildpack-ruby/compare/v201...v202
[v201]: https://github.com/heroku/heroku-buildpack-ruby/compare/v200...v201
[v200]: https://github.com/heroku/heroku-buildpack-ruby/compare/v199...v200
