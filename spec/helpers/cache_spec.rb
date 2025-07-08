require "spec_helper"

describe LanguagePack::Cache do
  it "cache to app with force: true/false" do
    with_cache_app do |cache_path:, app_path:|
      cache = LanguagePack::Cache.new(
        app_path: app_path,
        cache_path: cache_path
      )
      allow(cache).to receive(:copy)

      dir = Pathname("vendor/heroku")
      cache.cache_to_app(dir: dir, force: false)
      expect(cache).to have_received(:copy).with(
        cache_path.join(dir),
        app_path.join(dir),
        force: false
      ).once

      cache.cache_to_app(dir: dir, force: true)
      expect(cache).to have_received(:copy).with(
        cache_path.join(dir),
        app_path.join(dir),
        force: true
      ).once
    end
  end

  it "cache_to_app with rename" do
    with_cache_app do |cache_path:, app_path:|
      cache = LanguagePack::Cache.new(
        app_path: app_path,
        cache_path: cache_path
      )
      allow(cache).to receive(:copy)

      dir = Pathname("vendor/heroku")
      cache.cache_to_app(dir: dir, force: false, rename: "different_dir")
      expect(cache).to have_received(:copy).with(
        cache_path.join(dir),
        app_path.join("different_dir"),
        force: false
      ).once
    end
  end

  it "app to cache with force: true/false" do
    with_cache_app do |cache_path:, app_path:|
      cache = LanguagePack::Cache.new(
        app_path: app_path,
        cache_path: cache_path
      )
      allow(cache).to receive(:copy)

      dir = Pathname("vendor/heroku")
      cache.app_to_cache(dir: dir, force: false)
      expect(cache).to have_received(:copy).with(
        app_path.join(dir),
        cache_path.join(dir),
        force: false
      ).once

      cache.app_to_cache(dir: dir, force: true)
      expect(cache).to have_received(:copy).with(
        app_path.join(dir),
        cache_path.join(dir),
        force: true
      ).once
    end
  end

  it "app_to_cache with rename" do
    with_cache_app do |cache_path:, app_path:|
      cache = LanguagePack::Cache.new(
        app_path: app_path,
        cache_path: cache_path
      )
      allow(cache).to receive(:copy)

      dir = Pathname("vendor/heroku")
      cache.app_to_cache(dir: dir, force: false, rename: "different_dir")
      expect(cache).to have_received(:copy).with(
        app_path.join(dir),
        cache_path.join("different_dir"),
        force: false
      ).once
    end
  end

  it "cache_to_cache with force: true/false" do
    with_cache_app do |cache_path:, app_path:|
      cache = LanguagePack::Cache.new(
        app_path: app_path,
        cache_path: cache_path
      )
      allow(cache).to receive(:copy)

      dir = Pathname("vendor/heroku")
      cache.cache_to_cache(dir: dir, force: false, rename: "different_dir")
      expect(cache).to have_received(:copy).with(
        cache_path.join(dir),
        cache_path.join("different_dir"),
        force: false
      ).once

      cache.cache_to_cache(dir: dir, force: true, rename: "different_dir")
      expect(cache).to have_received(:copy).with(
        cache_path.join(dir),
        cache_path.join("different_dir"),
        force: true
      ).once
    end
  end

  def with_cache_app
    Dir.mktmpdir do |dir|
      cache_path = Pathname(dir).join("cache").tap(&:mkpath)
      app_path = Pathname(dir).join("app").tap(&:mkpath)
      yield cache_path: cache_path, app_path: app_path
    end
  end
end
