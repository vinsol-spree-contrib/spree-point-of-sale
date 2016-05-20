Spree::Core::Engine.routes.draw do
  get "admin/barcode/print_variants_barcodes/:id", to: "admin/barcode#print_variants_barcodes", as: :admin_barcode_print_variants_barcodes
  get "admin/barcode/print/:id", to: "admin/barcode#print", as: :admin_barcode_print
  get "admin/barcode/code/:id", to: "admin/barcode#code", as: :admin_barcode_code

  get "admin/pos/new" , to: "admin/pos#new", as: :new_admin_pos
  get "admin/pos/show/:number" , to: "admin/pos#show", as: :admin_pos_show_order
  post "admin/pos/clean/:number" , to: "admin/pos#clean_order", as: :admin_pos_clean_order
  get "admin/pos/find/:number" , to: "admin/pos#find", as: :find_admin_pos
  get "admin/pos/add/:number/:item" , to: "admin/pos#add", as: :add_admin_pos
  get "admin/pos/remove/:number/:item" , to: "admin/pos#remove", as: :remove_admin_pos
  post "admin/pos/associate_user/:number" , to: "admin/pos#associate_user", as: :associate_user_admin_pos
  post "admin/pos/update_payment/:number" , to: "admin/pos#update_payment", as: :update_payment_admin_pos
  post "admin/pos/update_line_item_quantity/:number" , to: "admin/pos#update_line_item_quantity", as: :update_line_item_quantity_admin_pos
  post "admin/pos/apply_discount/:number" , to: "admin/pos#apply_discount", as: :apply_discount_admin_pos

  get "admin/pos/index" , to: "admin/pos#new"
  post "admin/pos/update_stock_location/:number" , to: "admin/pos#update_stock_location", as: :update_stock_location_admin_pos
  get "admin/pos" , to: "admin/pos#new"
end
