require "spec_helper"

describe "bundle install with gem sources" do
  describe "install time dependencies" do
    it "installs gems with implicit rake dependencies" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "with_implicit_rake_dep"
        gem "another_implicit_rake_dep"
        gem "rake"
      G

      run <<-R
        require 'implicit_rake_dep'
        require 'another_implicit_rake_dep'
        puts IMPLICIT_RAKE_DEP
        puts ANOTHER_IMPLICIT_RAKE_DEP
      R
      out.should == "YES\nYES"
    end

    it "installs gems with a dependency with no type" do
      build_repo2

      path = "#{gem_repo2}/#{Gem::MARSHAL_SPEC_DIR}/actionpack-2.3.2.gemspec.rz"
      spec = Marshal.load(Gem.inflate(File.read(path)))
      spec.dependencies.each do |d|
        d.instance_variable_set(:@type, :fail)
      end
      File.open(path, 'w') do |f|
        f.write Gem.deflate(Marshal.dump(spec))
      end

      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "actionpack", "2.3.2"
      G

      should_be_installed "actionpack 2.3.2", "activesupport 2.3.2"
    end

    describe "with crazy rubygem plugin stuff" do
      it "installs plugins" do
        install_gemfile <<-G
          source "file://#{gem_repo1}"
          gem "net_b"
        G

        should_be_installed "net_b 1.0"
      end

      it "installs plugins depended on by other plugins" do
        install_gemfile <<-G
          source "file://#{gem_repo1}"
          gem "net_a"
        G

        should_be_installed "net_a 1.0", "net_b 1.0"
      end

      it "installs multiple levels of dependencies" do
        install_gemfile <<-G
          source "file://#{gem_repo1}"
          gem "net_c"
          gem "net_e"
        G

        should_be_installed "net_a 1.0", "net_b 1.0", "net_c 1.0", "net_d 1.0", "net_e 1.0"
      end
    end
  end
end