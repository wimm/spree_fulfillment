Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_fulfillment'
  s.version     = '0.60.1'
  s.summary     = 'Spree extension to do fulfillment processing via Amazon when a shipment becomes ready'
  s.required_ruby_version = '>= 1.9.2'
  s.required_rubygems_version = ">= 1.8.5"

  s.author            = 'Bill Lipa'
  s.email             = 'dojo@masterleep.com'
  s.homepage          = 'http://masterleep.com'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency('spree', '>= 0.60.1')
  s.add_dependency('active_fulfillment')
end
