Cloud Foundry buildpack: Ruby
======================

A Cloud Foundry [buildpack](http://docs.cloudfoundry.org/buildpacks/) for Ruby based apps.

This is based on the [Heroku buildpack] (https://github.com/heroku/heroku-buildpack-ruby).

Usage
-----

### Ruby

Example Usage:

```bash
cf push my_app --buildpack https://github.com/cloudfoundry/buildpack-ruby.git
```

This buildpack will be used if your app has a `Gemfile` and `Gemfile.lock` in the root directory. It will then use Bundler to install your dependencies. 


#### Run the Tests

There are [Machete](https://github.com/pivotal-cf-experimental/machete) based integration tests available in [cf_spec](cf_spec).

The test script is included in machete and can be run as follows:

```bash
BUNDLE_GEMFILE=cf.Gemfile bundle install
git submodule update --init
`BUNDLE_GEMFILE=cf.Gemfile bundle show machete`/scripts/buildpack-build [mode]
```

`buildpack-build` will create a buildpack in one of two modes and upload it to your local bosh-lite based Cloud Foundry installations.

Valid modes:

online : Dependencies can be fetched from the internet.

offline : Dependencies, such as ruby, are installed from a cache included in the buildpack.

The tests expect two Cloud Foundry installations to be present, an online one at 10.244.0.34 and an offline one at 10.245.0.34.

We use [bosh-lite](https://github.com/cloudfoundry/bosh-lite) for the online instance and [bosh-lite-2nd-instance](https://github.com/cf-buildpacks/bosh-lite-2nd-instance) for the offline instance.


Cloud Foundry Extensions
------------------------

The primary purpose of extending the heroku buildpack is to cache system dependencies for firewalled or other non-internet accessible environments. This is called 'offline' mode.

'offline' buildpacks can be used in any environment where you would prefer the dependencies to be cached instead of fetched from the internet.
 
The list of what is cached is maintained in [bin/package](bin/package).
 
Using cached system dependencies is accomplished by monkey-patching the heroku buildpack. See [lib/cloud_foundry/language_pack](lib/cloud_foundry/language_pack).

Offline mode expects each app to [vendor its dependencies using Bundler](http://bundler.io/v1.1/bundle_package.html). The alternative is to [set up a local rubygems server](http://guides.rubygems.org/run-your-own-gem-server).

Building
-------

1. Make sure you have fetched submodules

  ```bash
  git submodule update --init
  ```

1. Build the buildpack
    
  ```bash
  bin/package [ online | offline ]
  ```
    
1. Use in Cloud Foundry

    Either:
    
    Fork the repository, push your changes and specify the path when deploying your app
    ```bash
    cf push my_app --buildpack <new buildpack repository>
    ```
    
    OR
    
    Upload the buildpack to your Cloud Foundry and specify it by name
    
    ```bash
    cf create-buildpack custom_ruby_buildpack ruby_buildpack-offline-custom.zip 1
    ```

Contributing
-------

1. Fork the project
1. Submit a pull request
