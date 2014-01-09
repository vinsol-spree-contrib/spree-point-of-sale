Deface::Override.new(
  :virtual_path => 'spree/admin/orders/index',
  :name => 'add_is_pos_filter_to_admin_orders',
  :insert_bottom => ".omega.four.columns .field.checkbox",
  :text => %q{
    <label>
      <%= f.check_box :is_pos_eq, {}, '1', '' %>
      show only pos orders
    </label>
  }
)