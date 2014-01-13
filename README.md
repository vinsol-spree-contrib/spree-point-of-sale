SpreePos
===============
POS hooks into the Admin Tab and is meant to be used to sell inside a shop.

Allows you to search and add items available at the selected stock location, apply a discount to line items, save the customer email to associate the customer with the order and save the details of payment made to finally finish the order with an invoice ready to print.

The order is by default linked with the email of the admin accessing it.

An existing customer can be linked to the order by entering customer's email.
In case of a new customer, just enter the details and a new account will be created and the email will get linked to the order.

Order
=========
The order is started with a complete state with completed_at field set for it to facilitate the functioning for pos.

The order is linked to the admin creating the order, this helps to keep a track of pos orders initiated by a particular admin to avoid empty orders on access by admin at the pos tab. Admin won't be allowed to update a paid order or even to create a new order when there is an order pending to be paid.

Stock Location and Inventory
=========

By default the first active stock location is picked up considering a single stock location. In case of multiple stock locations you can easily over write the method user_stock_locations for pos_controller according to the scenario for your shop.

The inventory is updated along with addition and removal of items from the order.

Dependencies
============

spree_html_invoice

By default POS relies on html-invoice to print a receipt. You can configure this away by setting :pos_printing to the url where you want to redirect after print. 

Configure
=========
You must configure

1)ShippingMethod : It can be easily set from the admin end via general settings. 
Usually something like "pickup" with cost 0

2)Payment Methods : They can be added under PointOfSale payment method from admin end itself.

SKU
====
Barcode printing relies on sku to be provided for variants.

There are links provided to print barcodes for individual variants in the variants index for a product or barcodes for all variants can be printed from the product listings as well.

Installation
=======

To your Gemfile add:

  1) gem "spree_pos", :git => "git://github.com/vinsol/spree-point-of-sale.git"

  2) If you don't change the :pos_printing  config as described above, you must also add 

  gem 'spree_html_invoice' , :git => 'git://github.com/dancinglightning/spree-html-invoice.git'

and run bundler.