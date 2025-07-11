require "spec_helper"

describe LanguagePack::Cache do
  it "cache to app with overwrite: true/false" do
    with_cache_app do |cache_path:, app_path:|
      cache = LanguagePack::Cache.new(
        app_path: app_path,
        cache_path: cache_path,
        experiment_enabled: false
      )
      allow(cache).to receive(:copy)

      dir = Pathname("vendor/heroku")
      cache.cache_to_app(dir: dir, overwrite: false)
      expect(cache).to have_received(:copy).with(
        from_path: cache_path.join(dir),
        to_path: app_path.join(dir),
        name: "cache_to_app",
        overwrite: false
      ).once

      cache.cache_to_app(dir: dir, overwrite: true)
      expect(cache).to have_received(:copy).with(
        from_path: cache_path.join(dir),
        to_path: app_path.join(dir),
        name: "cache_to_app",
        overwrite: true
      ).once
    end
  end

  it "cache_to_app with rename" do
    with_cache_app do |cache_path:, app_path:|
      cache = LanguagePack::Cache.new(
        app_path: app_path,
        cache_path: cache_path,
        experiment_enabled: false
      )
      allow(cache).to receive(:copy)

      dir = Pathname("vendor/heroku")
      cache.cache_to_app(dir: dir, overwrite: false, rename: "different_dir")
      expect(cache).to have_received(:copy).with(
        from_path: cache_path.join(dir),
        to_path: app_path.join("different_dir"),
        name: "cache_to_app",
        overwrite: false
      ).once
    end
  end

  it "app to cache with overwrite: true/false" do
    with_cache_app do |cache_path:, app_path:|
      cache = LanguagePack::Cache.new(
        app_path: app_path,
        cache_path: cache_path,
        experiment_enabled: false
      )
      allow(cache).to receive(:copy)

      dir = Pathname("vendor/heroku")
      cache.app_to_cache(dir: dir, overwrite: false)
      expect(cache).to have_received(:copy).with(
        from_path: app_path.join(dir),
        to_path: cache_path.join(dir),
        name: "app_to_cache",
        overwrite: false
      ).once

      cache.app_to_cache(dir: dir, overwrite: true)
      expect(cache).to have_received(:copy).with(
        from_path: app_path.join(dir),
        to_path: cache_path.join(dir),
        name: "app_to_cache",
        overwrite: true,
      ).once
    end
  end

  it "app_to_cache with rename" do
    with_cache_app do |cache_path:, app_path:|
      cache = LanguagePack::Cache.new(
        app_path: app_path,
        cache_path: cache_path,
        experiment_enabled: false
      )
      allow(cache).to receive(:copy)

      dir = Pathname("vendor/heroku")
      cache.app_to_cache(dir: dir, overwrite: false, rename: "different_dir")
      expect(cache).to have_received(:copy).with(
        from_path: app_path.join(dir),
        to_path: cache_path.join("different_dir"),
        name: "app_to_cache",
        overwrite: false
      ).once
    end
  end

  it "copy_options heroku-22" do
    cache = LanguagePack::Cache.new(
      app_path: "/dev/null/app",
      cache_path: "/dev/null/cache",
      stack: "heroku-22",
      experiment_enabled: false
    )

    expect(cache.copy_options(overwrite: true)).to eq("-a")
    expect(cache.copy_options(overwrite: false)).to eq("-a -n")
  end

  it "copy_options heroku-24" do
    cache = LanguagePack::Cache.new(
      app_path: "/dev/null/app",
      cache_path: "/dev/null/cache",
      stack: "heroku-24",
      experiment_enabled: false
    )

    expect(cache.copy_options(overwrite: true)).to eq("-a")
    expect(cache.copy_options(overwrite: false)).to eq("-a --update=none")
  end

  def with_cache_app
    Dir.mktmpdir do |dir|
      cache_path = Pathname(dir).join("cache").tap(&:mkpath)
      app_path = Pathname(dir).join("app").tap(&:mkpath)
      yield cache_path: cache_path, app_path: app_path
    end
  end
end
