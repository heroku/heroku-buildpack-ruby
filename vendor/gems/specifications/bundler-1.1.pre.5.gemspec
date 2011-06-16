# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{bundler}
  s.version = "1.1.pre.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.authors = ["André Arko", "Terence Lee", "Carl Lerche", "Yehuda Katz"]
  s.date = %q{2011-06-10}
  s.default_executable = %q{bundle}
  s.description = %q{Bundler manages an application's dependencies through its entire life, across many machines, systematically and repeatably}
  s.email = ["andre@arko.net"]
  s.executables = ["bundle"]
  s.files = [".gitignore", ".travis.yml", "CHANGELOG.md", "ISSUES.md", "LICENSE", "README.md", "Rakefile", "UPGRADING.md", "bin/bundle", "bundler.gemspec", "lib/bundler.rb", "lib/bundler/capistrano.rb", "lib/bundler/cli.rb", "lib/bundler/definition.rb", "lib/bundler/dependency.rb", "lib/bundler/deployment.rb", "lib/bundler/dsl.rb", "lib/bundler/endpoint_specification.rb", "lib/bundler/environment.rb", "lib/bundler/fetcher.rb", "lib/bundler/gem_helper.rb", "lib/bundler/gem_tasks.rb", "lib/bundler/graph.rb", "lib/bundler/index.rb", "lib/bundler/installer.rb", "lib/bundler/lazy_specification.rb", "lib/bundler/lockfile_parser.rb", "lib/bundler/remote_specification.rb", "lib/bundler/resolver.rb", "lib/bundler/rubygems_ext.rb", "lib/bundler/rubygems_integration.rb", "lib/bundler/runtime.rb", "lib/bundler/settings.rb", "lib/bundler/setup.rb", "lib/bundler/shared_helpers.rb", "lib/bundler/source.rb", "lib/bundler/spec_set.rb", "lib/bundler/templates/Executable", "lib/bundler/templates/Gemfile", "lib/bundler/templates/newgem/Gemfile.tt", "lib/bundler/templates/newgem/Rakefile.tt", "lib/bundler/templates/newgem/bin/newgem.tt", "lib/bundler/templates/newgem/gitignore.tt", "lib/bundler/templates/newgem/lib/newgem.rb.tt", "lib/bundler/templates/newgem/lib/newgem/version.rb.tt", "lib/bundler/templates/newgem/newgem.gemspec.tt", "lib/bundler/ui.rb", "lib/bundler/vendor/net/http/faster.rb", "lib/bundler/vendor/net/http/persistent.rb", "lib/bundler/vendor/thor.rb", "lib/bundler/vendor/thor/actions.rb", "lib/bundler/vendor/thor/actions/create_file.rb", "lib/bundler/vendor/thor/actions/directory.rb", "lib/bundler/vendor/thor/actions/empty_directory.rb", "lib/bundler/vendor/thor/actions/file_manipulation.rb", "lib/bundler/vendor/thor/actions/inject_into_file.rb", "lib/bundler/vendor/thor/base.rb", "lib/bundler/vendor/thor/core_ext/file_binary_read.rb", "lib/bundler/vendor/thor/core_ext/hash_with_indifferent_access.rb", "lib/bundler/vendor/thor/core_ext/ordered_hash.rb", "lib/bundler/vendor/thor/error.rb", "lib/bundler/vendor/thor/invocation.rb", "lib/bundler/vendor/thor/parser.rb", "lib/bundler/vendor/thor/parser/argument.rb", "lib/bundler/vendor/thor/parser/arguments.rb", "lib/bundler/vendor/thor/parser/option.rb", "lib/bundler/vendor/thor/parser/options.rb", "lib/bundler/vendor/thor/shell.rb", "lib/bundler/vendor/thor/shell/basic.rb", "lib/bundler/vendor/thor/shell/color.rb", "lib/bundler/vendor/thor/shell/html.rb", "lib/bundler/vendor/thor/task.rb", "lib/bundler/vendor/thor/util.rb", "lib/bundler/vendor/thor/version.rb", "lib/bundler/vendored_thor.rb", "lib/bundler/version.rb", "lib/bundler/vlad.rb", "man/bundle-config.ronn", "man/bundle-exec.ronn", "man/bundle-install.ronn", "man/bundle-package.ronn", "man/bundle-update.ronn", "man/bundle.ronn", "man/gemfile.5.ronn", "man/index.txt", "spec/bundler/source_spec.rb", "spec/cache/gems_spec.rb", "spec/cache/git_spec.rb", "spec/cache/path_spec.rb", "spec/cache/platform_spec.rb", "spec/install/deploy_spec.rb", "spec/install/deprecated_spec.rb", "spec/install/gems/c_ext_spec.rb", "spec/install/gems/dependency_api_spec.rb", "spec/install/gems/env_spec.rb", "spec/install/gems/flex_spec.rb", "spec/install/gems/groups_spec.rb", "spec/install/gems/packed_spec.rb", "spec/install/gems/platform_spec.rb", "spec/install/gems/post_install_spec.rb", "spec/install/gems/resolving_spec.rb", "spec/install/gems/simple_case_spec.rb", "spec/install/gems/standalone_spec.rb", "spec/install/gems/sudo_spec.rb", "spec/install/gems/win32_spec.rb", "spec/install/gemspec_spec.rb", "spec/install/git_spec.rb", "spec/install/invalid_spec.rb", "spec/install/path_spec.rb", "spec/install/upgrade_spec.rb", "spec/lock/git_spec.rb", "spec/lock/lockfile_spec.rb", "spec/other/check_spec.rb", "spec/other/clean_spec.rb", "spec/other/config_spec.rb", "spec/other/console_spec.rb", "spec/other/exec_spec.rb", "spec/other/ext_spec.rb", "spec/other/gem_helper_spec.rb", "spec/other/help_spec.rb", "spec/other/init_spec.rb", "spec/other/newgem_spec.rb", "spec/other/open_spec.rb", "spec/other/outdated_spec.rb", "spec/other/show_spec.rb", "spec/pack/gems_spec.rb", "spec/quality_spec.rb", "spec/resolver/basic_spec.rb", "spec/resolver/platform_spec.rb", "spec/runtime/executable_spec.rb", "spec/runtime/load_spec.rb", "spec/runtime/platform_spec.rb", "spec/runtime/require_spec.rb", "spec/runtime/setup_spec.rb", "spec/runtime/with_clean_env_spec.rb", "spec/spec_helper.rb", "spec/support/artifice/endpoint.rb", "spec/support/artifice/endpoint_basic_authentication.rb", "spec/support/artifice/endpoint_fallback.rb", "spec/support/artifice/endpoint_marshal_fail.rb", "spec/support/artifice/endpoint_redirect.rb", "spec/support/builders.rb", "spec/support/fakeweb/rack-1.0.0.marshal", "spec/support/fakeweb/windows.rb", "spec/support/helpers.rb", "spec/support/indexes.rb", "spec/support/matchers.rb", "spec/support/path.rb", "spec/support/platforms.rb", "spec/support/ruby_ext.rb", "spec/support/rubygems_ext.rb", "spec/support/rubygems_hax/platform.rb", "spec/support/sudo.rb", "spec/update/gems_spec.rb", "spec/update/git_spec.rb", "spec/update/source_spec.rb", "lib/bundler/man/bundle-exec", "lib/bundler/man/bundle", "lib/bundler/man/bundle-install", "lib/bundler/man/gemfile.5", "lib/bundler/man/bundle-benchmark", "lib/bundler/man/bundle-package", "lib/bundler/man/bundle-update", "lib/bundler/man/bundle-exec.txt", "lib/bundler/man/gemfile.5.txt", "lib/bundler/man/bundle-update.txt", "lib/bundler/man/bundle-config", "lib/bundler/man/bundle-config.txt", "lib/bundler/man/bundle-benchmark.txt", "lib/bundler/man/bundle.txt", "lib/bundler/man/bundle-package.txt", "lib/bundler/man/bundle-install.txt"]
  s.homepage = %q{http://gembundler.com}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{bundler}
  s.rubygems_version = %q{1.3.9.2}
  s.summary = %q{The best way to manage your application's dependencies}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<ronn>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.0"])
    else
      s.add_dependency(%q<ronn>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.0"])
    end
  else
    s.add_dependency(%q<ronn>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.0"])
  end
end
