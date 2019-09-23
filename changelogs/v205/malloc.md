## Default `MALLOC_ARENA_MAX=2` for new Ruby applications

The environment variable `MALLOC_ARENA_MAX` will now default to `2` for Ruby applications. This environment variable was
previously unset. This change will only affect new applications on the platform, to update an existing application please
run:

```
$ heroku config:set MALLOC_ARENA_MAX=2
```

The goal of setting this value is to decrease memory usage for the majority of Ruby applications that are using threads
such as apps that use Sidekiq or Puma. To understand more about the relationship between this value and memory please see
the following external resources:

- https://www.speedshop.co/2017/12/04/malloc-doubles-ruby-memory.html
- https://www.mikeperham.com/2018/04/25/taming-rails-memory-bloat/

We also maintain our own [documentation on tuning the memory behavior of glibc by setting this environment variable](https://devcenter.heroku.com/articles/tuning-glibc-memory-behavior).

If a your application is not memory bound and would prefer slightly faster execution over the decreased memory use,
you can set their `MALLOC_ARENA_MAX` to a higher value. The default as specified by the [linux man page](http://man7.org/linux/man-pages/man3/mallopt.3.html)
is 8 times the number of cores on the system.

## Jemalloc

Another popular alternative memory allocator is jemalloc. At this time Heroku does not maintain a supported version of this memory allocator,
but you can use it in your application with a 3rd party [jemalloc buildpack](https://elements.heroku.com/buildpacks/mojodna/heroku-buildpack-jemalloc).

If you are using jemalloc, setting `MALLOC_ARENA_MAX` will have no impact on memory or performance. For more information on
how jemalloc interacts with Ruby applications see this external post:

- https://www.speedshop.co/2017/12/04/malloc-doubles-ruby-memory.html#fix-2-use-jemalloc
