source "https://rubygems.org"
gem 'rails', '4.0.2'
gem 'mysql2'


gem 'spree', :git => 'git://github.com/spree/spree.git', :tag => 'v2.1.4'
# gem 'spree_html_invoice' , :git => 'git://github.com/dancinglightning/spree-html-invoice.git'

# Provides basic authentication functionality for testing parts of your engine
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', :branch => '2-1-stable'

gemspec

group :test do
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'simplecov', :require => false
  gem 'database_cleaner'
  gem 'rspec-html-matchers'
end
