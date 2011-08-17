SpreePos
===============

A Point Of Sale (POS) screen for Spree.

POS screen hooks into the Admin Tabs and is meant to be used with a touchscreen (ie big fonts etc).

Basic Bar scanner input (sku search) or search by name. No Customer, no shipping, no coupons...

Allows for adjustment of line item prices and discount percentage of items and total 

An actual Order is only created when you press print. 

Pressing new will abandon the current sale. Also, there is no way to get to the pos screen from an existing order, if those need to be edited, do so in the orders tab.

Configure
=========

And Order must be shipped, so you must configure a ShippingMethod to be used. If you don't the first will be
taken, rarely what you want.

Spree::Config.set(:pos_shipping => "id_or_name")

You can use this feature to give a discount or do whatever else you can do with shipments. We use 0€ .

Dependencies
============
None..... but

Pos relies on html-invoice to print a receipt. The dependency is not made explicit in case you don't need receipts. If you do add spree-html-invoice to your gemfile you _will_ want to configure the look of the receipt.

You can install spree-product-barcodes to print product labels if need be. Otherwise use the existing upc barcodes on the products and scan them into the sku.

ToDo
====
I'm just starting and this is just starting to get there (I'm not even using it).

TAXES will be a surprise for ANYONE (vat/sales , still working on it...)

Installation
=======

Add to your Gemfile with 

  gem "spree_pos", :git => "git://github.com/dancinglightning/spree-pos.git"

and run bundler.


Copyright (c) 2011 [Torsten Rüger], released under the New BSD License
