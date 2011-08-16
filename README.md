SpreePos
===============

A Point Of Sale (POS) screen for Spree.

POS screen hooks into the Admin Tabs and is mean to be used with a touchscreen (ie big fonts etc).

Basic Bar scanner input (sku search) or search by name. No Customer, no shipping, no coupons...

Allows for adjustment of line item prices and percentage discount of total 

Configure
=========

And Order must be shipped, so you must configure a ShippingMethod to be used. If you don't the first will be
taken, rarely what you want.

Spree::Config.set(:pos_shipping => "id_or_name")

You can use this feature to give a discount or do whatever else you can do with shipments. We use 0€ .

Dependencies
============
None..... but

Pos relies on html-invoice to print a receipt. The dependency is not made explicit in case you don't need receipts. If you do add spree-html-invoice to your gemfile and you _will_ want to configure the look of the receipt.

ToDo
====
I'm just starting and THIS IS NOT READY, especially not for use.

discounts and adjustments missing

Installation
=======

Add to your Gemfile with 

  gem "spree_pos", :git => "git://github.com/dancinglightning/spree-pos.git"

and run bundler.


Copyright (c) 2011 [Torsten Rüger], released under the New BSD License
