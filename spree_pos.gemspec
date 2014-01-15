# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = "spree_pos"
  s.version = "1.1"

  s.authors = ["Torsten R, Manish Kangia"]

  s.date = "2013-07-29"

  s.email     = 'info@vinsol.com'
  s.homepage  = 'http://vinsol.com'  

  s.files     = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")

  s.requirements = ["none"]
  s.rubygems_version = "2.0.3"

  s.summary = "Point of sale screen for Spree"
  s.description = "Extend functionality for spree to give shop like ordering ability through admin end"


  s.add_dependency('spree_core', '~> 2.0.0')
  s.add_dependency('barby', '>= 0')
end
