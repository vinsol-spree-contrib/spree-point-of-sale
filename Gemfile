source "https://rubygems.org"
gem 'rails', '3.2.16'
gem 'mysql2'


# gem 'spree', :git => 'git://github.com/spree/spree.git', :tag => 'v2.0.3'
# gem 'spree_html_invoice' , :git => 'git://github.com/dancinglightning/spree-html-invoice.git'

# Provides basic authentication functionality for testing parts of your engine
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', :branch => '2-0-stable'
gem 'barby'

gemspec

group :test do
  gem 'rspec-rails', '~> 2.10'
  gem 'shoulda-matchers', '2.2.0'
  gem 'simplecov', :require => false
  gem 'database_cleaner'
  gem 'rspec-html-matchers'
end
