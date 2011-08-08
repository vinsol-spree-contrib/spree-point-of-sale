class SpreePosHooks < Spree::ThemeSupport::HookListener
  insert_after :admin_tabs do
    %( <%= tab :pos %>)
  end
  
#  insert_before :admin_order_show_addresses , 'admin/pos/order_task_link'
#  insert_before :admin_product_form_right , 'admin/pos/product_task_link'
  
#  insert_after :admin_orders_index_row_actions , 'admin/pos/order_icon_link'
#  insert_after :admin_products_index_row_actions , 'admin/pos/product_icon_link'
  
end