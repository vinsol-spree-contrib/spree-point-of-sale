Spree::Core::Engine.routes.prepend do
  namespace :admin do

    match "pos/new" => "pos#new"
    match "pos/show/:number" => "pos#show"
    match "pos/find/:number" => "pos#find"
    match "pos/add/:number/:item" => "pos#add"
    match "pos/remove/:number/:item" => "pos#remove"
    match "pos/print/:number" => "pos#print"
#    match "pos/export" => "pos#export" 
#    match "pos/import" => "pos#import" 
#    match "pos/index" => "pos#index"
    match "pos/inventory/:number" => "pos#inventory"
    get "pos" , :to => "pos#new"
  end
#  match '/admin' => 'admin/pos#index', :as => :admin
end

