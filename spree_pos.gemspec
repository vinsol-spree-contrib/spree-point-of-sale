Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_pos'
  s.version     = '1.1'
  s.summary     = 'Point of sale screen for Spree'
  s.required_ruby_version = '>= 1.8.7'

  s.author            = 'Torsten R'
  s.email             = 'torsten@villataika.fi'

  s.files        = Dir['CHANGELOG', 'README.md', 'LICENSE', 'lib/**/*', 'app/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'


  s.add_dependency('spree_core', '>= 1.1')
end