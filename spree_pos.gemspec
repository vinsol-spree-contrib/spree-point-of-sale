# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = "spree_pos"
  s.version = "1.1"

  s.authors = ["Torsten R, Manish Kangia"]
  s.date = "2013-07-29"
  s.email     = 'info@vinsol.com'
  s.homepage  = 'http://vinsol.com'  
  s.files = ["README.md", "LICENSE", "lib/generators", "lib/generators/spree_pos", "lib/generators/spree_pos/install", "lib/generators/spree_pos/install/install_generator.rb", "lib/spree_pos", "lib/spree_pos/configuration.rb", "lib/spree_pos/engine.rb", "lib/spree_pos.rb", "app/assets", "app/assets/images", "app/assets/images/admin", "app/assets/images/admin/pos", "app/assets/images/admin/pos/10.jpg", "app/assets/images/admin/pos/10.png", "app/assets/images/admin/pos/15.jpg", "app/assets/images/admin/pos/15.png", "app/assets/images/admin/pos/20.jpg", "app/assets/images/admin/pos/20.png", "app/assets/images/admin/pos/25.jpg", "app/assets/images/admin/pos/25.png", "app/assets/images/admin/pos/5.jpg", "app/assets/images/admin/pos/5.png", "app/assets/images/admin/pos/barcode.jpg", "app/assets/images/admin/pos/close.gif", "app/assets/images/admin/pos/close_print.gif", "app/assets/images/admin/pos/close_print.png", "app/assets/images/admin/pos/customer.gif", "app/assets/images/admin/pos/customer.png", "app/assets/images/admin/pos/delete.png", "app/assets/images/admin/pos/delete_discount.png", "app/assets/images/admin/pos/export.jpg", "app/assets/images/admin/pos/inventory.png", "app/assets/images/admin/pos/inventory_plus.png", "app/assets/images/admin/pos/order.jpg", "app/assets/images/admin/pos/plus.png", "app/assets/images/admin/pos/print.gif", "app/assets/images/admin/pos/print.png", "app/assets/images/admin/pos/select.jpg", "app/assets/stylesheets", "app/assets/stylesheets/admin", "app/assets/stylesheets/admin/html-label.css", "app/controllers", "app/controllers/spree", "app/controllers/spree/admin", "app/controllers/spree/admin/barcode_controller.rb", "app/controllers/spree/admin/pos_controller.rb", "app/helpers", "app/helpers/admin", "app/helpers/admin/barcode_helper.rb", "app/helpers/admin/pos_helper.rb", "app/overrides", "app/overrides/add_pos_button.rb", "app/overrides/codes.rb", "app/overrides/ean_fields.rb", "app/overrides/pos_tab.rb", "app/views", "app/views/spree", "app/views/spree/admin", "app/views/spree/admin/barcode", "app/views/spree/admin/barcode/basic.html.erb", "app/views/spree/admin/orders", "app/views/spree/admin/orders/_pos_button.html.erb", "app/views/spree/admin/pos", "app/views/spree/admin/pos/find.html.erb", "app/views/spree/admin/pos/show.html.erb", "app/views/spree/admin/products", "app/views/spree/admin/products/_barcode_product_link.html.erb", "app/views/spree/admin/products/_barcode_variant_link.html.erb"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")
  s.requirements = ["none"]
  s.rubygems_version = "2.0.3"
  s.summary = "Point of sale screen for Spree"
  s.description = "Extend functionality for spree to give shop like ordering ability through admin end"

  # s.add_runtime_dependency(%q<spree_core>, ["~> 2.0.0"])
  # s.add_runtime_dependency(%q<spree_backend>, ["~> 2.0.0"])
  # s.add_dependency('spree_html_invoice', [">=0"])
  s.add_dependency(%q<barby>, [">= 0"])
  s.add_dependency(%q<prawn>, [">= 0"])
  s.add_dependency(%q<rqrcode>, [">= 0"])
  s.add_dependency(%q<chunky_png>, [">= 0"])
end
