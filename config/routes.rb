Spree::Core::Engine.routes.prepend do
  namespace :admin do
    match "barcode/print_variants_barcodes/:id" => "barcode#print_variants_barcodes"
    match "barcode/print/:id" => "barcode#print"
    # match "barcode/code/:id" => "barcode#code"

    match "pos/new" => "pos#new"
    match "pos/show/:number" => "pos#show", :as => :pos_show_order
    match "pos/clean/:number" => "pos#clean_order", :as => :pos_clean_order
    match "pos/find/:number" => "pos#find"
    match "pos/add/:number/:item" => "pos#add"
    match "pos/remove/:number/:item" => "pos#remove"
    # match "pos/print/:number" => "pos#print"
    match "pos/associate_user/:number" => "pos#associate_user"
    match "pos/update_payment/:number" => "pos#update_payment"
#    match "pos/export" => "pos#export" 
#    match "pos/import" => "pos#import" 
    match "pos/index" => "pos#new"
    # match "pos/inventory/:number" => "pos#inventory"
    match "pos/update_stock_location/:number" => "pos#update_stock_location", :via => :put
    get "pos" , :to => "pos#new"
  end
#  match '/admin' => 'admin/pos#index', :as => :admin
end