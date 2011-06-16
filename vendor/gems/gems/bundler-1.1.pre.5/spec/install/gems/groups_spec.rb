require "spec_helper"

describe "bundle install with gem sources" do
  describe "with groups" do
    describe "installing with no options" do
      before :each do
        install_gemfile <<-G
          source "file://#{gem_repo1}"
          gem "rack"
          group :emo do
            gem "activesupport", "2.3.5"
          end
          gem "thin", :groups => [:emo]
        G
      end

      it "installs gems in the default group" do
        should_be_installed "rack 1.0.0"
      end

      it "installs gems in a group block into that group" do
        should_be_installed "activesupport 2.3.5"

        run("require 'activesupport'; puts ACTIVESUPPORT",
          :default, :expect_err => true)
        @err.should =~ /no such file to load -- activesupport/
      end

      it "installs gems with inline :groups into those groups" do
        should_be_installed "thin 1.0"

        run("require 'thin'; puts THIN", :default, :expect_err => true)
        @err.should =~ /no such file to load -- thin/
      end

      it "sets up everything if Bundler.setup is used with no groups" do
        out = run("require 'rack'; puts RACK")
        out.should eq('1.0.0')

        out = run("require 'activesupport'; puts ACTIVESUPPORT")
        out.should eq('2.3.5')

        out = run("require 'thin'; puts THIN")
        out.should eq('1.0')
      end

      it "removes old groups when new groups are set up" do
        run <<-RUBY, :emo, :expect_err => true
          Bundler.setup(:default)
          require 'thin'; puts THIN
        RUBY
        @err.should =~ /no such file to load -- thin/i
      end

      it "sets up old groups when they have previously been removed" do
        out = run <<-RUBY, :emo
          Bundler.setup(:default)
          Bundler.setup(:default, :emo)
          require 'thin'; puts THIN
        RUBY
        out.should == '1.0'
      end
    end

    describe "installing --without" do
      describe "with gems assigned to a single group" do
        before :each do
          gemfile <<-G
            source "file://#{gem_repo1}"
            gem "rack"
            group :emo do
              gem "activesupport", "2.3.5"
            end
          G
        end

        it "installs gems in the default group" do
          bundle :install, :without => "emo"
          should_be_installed "rack 1.0.0", :groups => [:default]
        end

        it "does not install gems from the excluded group" do
          bundle :install, :without => "emo"
          should_not_be_installed "activesupport 2.3.5", :groups => [:default]
        end

        it "does not install gems from the previously excluded group" do
          bundle :install, :without => "emo"
          should_not_be_installed "activesupport 2.3.5"
          bundle :install
          should_not_be_installed "activesupport 2.3.5"
        end

        it "does not say it installed gems from the excluded group" do
          bundle :install, :without => "emo"
          out.should_not include("activesupport")
        end

        it "allows Bundler.setup for specific groups" do
          bundle :install, :without => "emo"
          run("require 'rack'; puts RACK", :default)
          out.should == '1.0.0'
        end

        it "does not effect the resolve" do
          gemfile <<-G
            source "file://#{gem_repo1}"
            gem "activesupport"
            group :emo do
              gem "rails", "2.3.2"
            end
          G

          bundle :install, :without => "emo"
          should_be_installed "activesupport 2.3.2", :groups => [:default]
        end

        it "still works on a different machine and excludes gems" do
          bundle :install, :without => "emo"

          simulate_new_machine
          bundle :install, :without => "emo"

          should_be_installed "rack 1.0.0", :groups => [:default]
          should_not_be_installed "activesupport 2.3.5", :groups => [:default]
        end

        it "still works when BUNDLE_WITHOUT is set" do
          ENV["BUNDLE_WITHOUT"] = "emo"

          bundle :install
          out.should_not include("activesupport")

          should_be_installed "rack 1.0.0", :groups => [:default]
          should_not_be_installed "activesupport 2.3.5", :groups => [:default]

          ENV["BUNDLE_WITHOUT"] = nil
        end
      end

      describe "with gems assigned to multiple groups" do
        before :each do
          gemfile <<-G
            source "file://#{gem_repo1}"
            gem "rack"
            group :emo, :lolercoaster do
              gem "activesupport", "2.3.5"
            end
          G
        end

        it "installs gems in the default group" do
          bundle :install, :without => "emo lolercoaster"
          should_be_installed "rack 1.0.0"
        end

        it "installs the gem if any of its groups are installed" do
          bundle "install --without emo"
          should_be_installed "rack 1.0.0", "activesupport 2.3.5"
        end

        it "works when locked as well" do
          bundle "install --without emo"
          bundle "lock"

          simulate_new_machine

          bundle "install --without lolercoaster"
          should_be_installed "rack 1.0.0", "activesupport 2.3.5"
        end

        describe "with a gem defined multiple times in different groups" do
          before :each do
            gemfile <<-G
              source "file://#{gem_repo1}"
              gem "rack"

              group :emo do
                gem "activesupport", "2.3.5"
              end

              group :lolercoaster do
                gem "activesupport", "2.3.5"
              end
            G
          end

          it "installs the gem w/ option --without emo" do
            bundle "install --without emo"
            should_be_installed "activesupport 2.3.5"
          end

          it "installs the gem w/ option --without lolercoaster" do
            bundle "install --without lolercoaster"
            should_be_installed "activesupport 2.3.5"
          end

          it "does not install the gem w/ option --without emo lolercoaster" do
            bundle "install --without emo lolercoaster"
            should_not_be_installed "activesupport 2.3.5"
          end

          it "does not install the gem w/ option --without 'emo lolercoaster'" do
            bundle "install --without 'emo lolercoaster'"
            should_not_be_installed "activesupport 2.3.5"
          end
        end
      end

      describe "nesting groups" do
        before :each do
          gemfile <<-G
            source "file://#{gem_repo1}"
            gem "rack"
            group :emo do
              group :lolercoaster do
                gem "activesupport", "2.3.5"
              end
            end
          G
        end

        it "installs gems in the default group" do
          bundle :install, :without => "emo lolercoaster"
          should_be_installed "rack 1.0.0"
        end

        it "installs the gem if any of its groups are installed" do
          bundle "install --without emo"
          should_be_installed "rack 1.0.0", "activesupport 2.3.5"
        end

        it "works when locked as well" do
          bundle "install --without emo"
          bundle "lock"

          simulate_new_machine

          bundle "install --without lolercoaster"
          should_be_installed "rack 1.0.0", "activesupport 2.3.5"
        end
      end
    end
  end
end
