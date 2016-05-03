Deface::Override.new(
  virtual_path: 'spree/admin/stock_locations/_form',
  name: 'add_store_to_spree_stock_locations',
  insert_bottom: "[data-hook='admin_stock_locations_form_fields']",
  text: %q{
    <div class='form-group'>
      <%= f.label :store, Spree.t(:store) + ':' %>
      <%= f.check_box :store %>
    </div>
    }
)
