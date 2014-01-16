Spree::Core::Engine.routes.prepend do
  namespace :admin do
    match "barcode/print_variants_barcodes/:id" => "barcode#print_variants_barcodes"
    match "barcode/print/:id" => "barcode#print"

    match "pos/new" => "pos#new"
    match "pos/show/:number" => "pos#show", :as => :pos_show_order
    match "pos/clean/:number" => "pos#clean_order", :as => :pos_clean_order
    match "pos/find/:number" => "pos#find"
    match "pos/add/:number/:item" => "pos#add"
    match "pos/remove/:number/:item" => "pos#remove"
    match "pos/associate_user/:number" => "pos#associate_user"
    match "pos/update_payment/:number" => "pos#update_payment"
    match "pos/update_line_item_quantity/:number" => "pos#update_line_item_quantity" 
    match "pos/apply_discount/:number" => "pos#apply_discount" 

    match "pos/index" => "pos#new"
    match "pos/update_stock_location/:number" => "pos#update_stock_location"
    get "pos" , :to => "pos#new"
  end
end