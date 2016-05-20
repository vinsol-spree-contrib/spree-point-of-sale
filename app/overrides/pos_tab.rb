Deface::Override.new(
  virtual_path: "spree/layouts/admin",
  name: "Add Pos tab to menu",
  insert_bottom: "[data-hook='admin_tabs']",
  partial: 'spree/admin/shared/add_pos_button',
  sequence: { after: "promo_admin_tabs" },
  disabled: false
)
