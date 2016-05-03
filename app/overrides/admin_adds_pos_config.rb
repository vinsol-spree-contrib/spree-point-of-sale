Deface::Override.new(
 virtual_path: "spree/admin/general_settings/edit",
 name: "add_adds_pos_config",
 insert_after: "div.security",
 partial: "spree/admin/orders/admin_pos_config",
 disabled: false
)
