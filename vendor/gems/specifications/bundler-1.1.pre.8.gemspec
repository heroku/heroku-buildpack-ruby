# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{bundler}
  s.version = "1.1.pre.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{AndrÃ© Arko}, %q{Terence Lee}, %q{Carl Lerche}, %q{Yehuda Katz}]
  s.date = %q{2011-08-15}
  s.description = %q{Bundler manages an application's dependencies through its entire life, across many machines, systematically and repeatably}
  s.email = [%q{andre@arko.net}]
  s.executables = [%q{bundle}]
  s.files = [%q{bin/bundle}]
  s.homepage = %q{http://gembundler.com}
  s.require_paths = [%q{lib}]
  s.rubyforge_project = %q{bundler}
  s.rubygems_version = %q{1.8.7}
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
