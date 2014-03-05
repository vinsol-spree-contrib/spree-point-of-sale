Spree::Core::Engine.routes.draw do
  get "admin/barcode/print_variants_barcodes/:id", to: "admin/barcode#print_variants_barcodes"
  get "admin/barcode/print/:id", to: "admin/barcode#print"

  get "admin/pos/new" , to: "admin/pos#new"
  get "admin/pos/show/:number" , to: "admin/pos#show", as: :admin_pos_show_order
  post "admin/pos/clean/:number" , to: "admin/pos#clean_order", as: :admin_pos_clean_order
  get "admin/pos/find/:number" , to: "admin/pos#find"
  get "admin/pos/add/:number/:item" , to: "admin/pos#add"
  get "admin/pos/remove/:number/:item" , to: "admin/pos#remove"
  post "admin/pos/associate_user/:number" , to: "admin/pos#associate_user"
  post "admin/pos/update_payment/:number" , to: "admin/pos#update_payment"
  post "admin/pos/update_line_item_quantity/:number" , to: "admin/pos#update_line_item_quantity" 
  post "admin/pos/apply_discount/:number" , to: "admin/pos#apply_discount" 

  get "admin/pos/index" , to: "admin/pos#new"
  post "admin/pos/update_stock_location/:number" , to: "admin/pos#update_stock_location"
  get "admin/pos" , to: "admin/pos#new"
end