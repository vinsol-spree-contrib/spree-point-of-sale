Deface::Override.new(
  virtual_path: 'spree/admin/variants/_form',
  name: "Add product label button",
  insert_bottom: "[data-hook='admin_variant_form_fields']",
  partial: "spree/admin/products/barcode_variant_link",
  disabled: false
)
Deface::Override.new(
  virtual_path: 'spree/admin/products/_form',
  name: "Add product label button",
  insert_bottom: '[data-hook="admin_product_form_fields"]',
  partial: "spree/admin/products/barcode_product_link",
  disabled: false
)
