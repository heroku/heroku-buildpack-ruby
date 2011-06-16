require "spec_helper"

describe "bundle cache with multiple platforms" do
  before :each do
    gemfile <<-G
      source "file://#{gem_repo1}"

      platforms :ruby, :ruby_18, :ruby_19 do
        gem "rack", "1.0.0"
      end

      platforms :jruby do
        gem "activesupport", "2.3.5"
      end

      platforms :mri, :mri_18, :mri_19 do
        gem "activerecord", "2.3.2"
      end
    G

    lockfile <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          rack (1.0.0)
          activesupport (2.3.5)
          activerecord (2.3.2)

      PLATFORMS
        ruby
        java

      DEPENDENCIES
        rack (1.0.0)
        activesupport (2.3.5)
        activerecord (2.3.2)
    G

    cache_gems "rack-1.0.0", "activesupport-2.3.5", "activerecord-2.3.2"
  end

  it "ensures that bundle install does not delete gems for other platforms" do
    bundle "install"

    bundled_app("vendor/cache/rack-1.0.0.gem").should exist
    bundled_app("vendor/cache/activesupport-2.3.5.gem").should exist
    bundled_app("vendor/cache/activerecord-2.3.2.gem").should exist
  end

  it "ensures that bundle update does not delete gems for other platforms" do
    bundle "update"

    bundled_app("vendor/cache/rack-1.0.0.gem").should exist
    bundled_app("vendor/cache/activesupport-2.3.5.gem").should exist
    bundled_app("vendor/cache/activerecord-2.3.2.gem").should exist
  end
end
