Spree Pos [![Code Climate](https://codeclimate.com/github/vinsol/spree-point-of-sale.png)](https://codeclimate.com/github/vinsol/spree-point-of-sale) [![Build Status](https://travis-ci.org/vinsol/spree-point-of-sale.png?branch=master)](https://travis-ci.org/vinsol/spree-point-of-sale)
=========
SpreePos hooks into the Admin Tab and is meant to be used to sell at a shop.

Allows you to search and add items available at the selected stock location. 
Apply discount on items, associate the order to customer email and save the details of payment to finally finish the order with an invoice ready to print.


Dependencies
============
1) spree_html_invoice (optional)

By default POS relies on html-invoice to print a receipt. You can configure this away by setting :pos_printing to the url where you want to redirect after print. 

2) barby

3) prawn

4) chunky_png


SET UP
=======
To your Gemfile add:

Add spree-point-of-sale to your Gemfile:

```ruby
gem "spree-point-of-sale"
```

For specific spree versions:

```ruby
#Spree 2.0.x
gem "spree-point-of-sale", '1.0.3'
```

```ruby
#Spree 2.1.x
gem "spree-point-of-sale", '1.1.1'
```

```ruby
#Spree 2.2.x
gem "spree-point-of-sale", '1.2.1'
```

If you DONT change the :pos_printing config as described above, you must also add 

```ruby
gem 'spree_html_invoice' , :git => 'git://github.com/vinsol/spree-html-invoice.git', tag: '1.2'
```

```ruby
bundle install
```

Finally for migrations, css and javascript do

```ruby
bundle exec rails g spree_pos:install
```

Configure
=========
You must configure:

1) ShippingMethod : Create a shipping method for pos and set it from the admin end via general settings. 
Usually something like "pickup" with cost 0.

2) Payment Methods : They can be added under PointOfSale payment method from admin end itself.

3) Store : Make sure atleast one of your stock locations is marked as store.


Order
=========
The order is linked to the admin creating the order to keep a track of pos orders initiated by a particular admin.

Admin won't be allowed to update a paid order or even to create a new order when there is an order pending to be paid.


Stock Location and Inventory
=========
By default the first active stock location is picked up considering a single stock location. In case of multiple stock locations you can easily switch them.

Stock Locations available to be selected can be easily configured by re-defining user_stock_locations for pos_controller.

The inventory is updated along with addition and removal of items from the order.


Barcode printing and SKU
========
Barcode printing relies on sku to be provided for variants.

There are links provided to print barcodes for individual variants in the variants index for a product or barcodes for all variants can be printed from the product listings as well.


Testing
---------
Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.
```ruby
bundle
bundle exec rake test_app
bundle exec rspec spec
```


Credits
-------

[![vinsol.com: Ruby on Rails, iOS and Android developers](http://vinsol.com/vin_logo.png "Ruby on Rails, iOS and Android developers")](http://vinsol.com)

Copyright (c) 2014 [vinsol.com](http://vinsol.com "Ruby on Rails, iOS and Android developers"), released under the New MIT License
