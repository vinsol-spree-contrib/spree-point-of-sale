Spree::Core::Engine.routes.draw do
  match "admin/barcode/print_variants_barcodes/:id" => "barcode#print_variants_barcodes", via: [:get]
  match "admin/barcode/print/:id" => "barcode#print", via: [:get]

  match "admin/pos/new" => "pos#new", via: [:get]
  match "admin/pos/show/:number" => "pos#show", :as => :admin_pos_show_order, via: [:get]
  match "admin/pos/clean/:number" => "pos#clean_order", :as => :admin_pos_clean_order, via: [:get]
  match "admin/pos/find/:number" => "pos#find", via: [:get]
  match "admin/pos/add/:number/:item" => "pos#add", via: [:get]
  match "admin/pos/remove/:number/:item" => "pos#remove", via: [:get]
  match "admin/pos/associate_user/:number" => "pos#associate_user", via: [:get]
  match "admin/pos/update_payment/:number" => "pos#update_payment", via: [:get]
  match "admin/pos/update_line_item_quantity/:number" => "pos#update_line_item_quantity", via: [:get]
  match "admin/pos/apply_discount/:number" => "pos#apply_discount", via: [:get]

  match "admin/pos/index" => "pos#new", via: [:get]
  match "admin/pos/update_stock_location/:number" => "pos#update_stock_location", via: [:get]
get "admin/pos" , :to => "pos#new"
end