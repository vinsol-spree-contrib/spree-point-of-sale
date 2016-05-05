source "https://rubygems.org"
gem 'rails', '4.2.6'
gem 'mysql2'
gem 'sass-rails'
gem 'coffee-rails'

gem 'spree', '> 3.0.0' #, :git => 'https://github.com/spree/spree.git', :tag => 'v2.2.0'
# gem 'spree_html_invoice' , :git => 'git://github.com/dancinglightning/spree-html-invoice.git'

# Provides basic authentication functionality for testing parts of your engine
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: '3-0-stable'
gemspec

group :test do
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'database_cleaner'
  gem 'rspec-html-matchers'
  gem 'rspec-activemodel-mocks', '~> 1.0.3'
end
