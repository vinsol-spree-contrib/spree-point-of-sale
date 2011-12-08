Rails.application.routes.draw do
  namespace :admin do
    match "pos/new" => "pos#new"
    match "pos/export" => "pos#export" 
    match "pos/import" => "pos#import" 
    match "pos/add/:item" => "pos#add"
    match "pos/remove/:item" => "pos#remove"
    match "pos/find" => "pos#find"
    match "pos/index" => "pos#index"
    match "pos/print" => "pos#print"
    match "pos/inventory" => "pos#inventory"
    match "pos" => "pos#index"
  end
#  match '/admin' => 'admin/pos#index', :as => :admin
end

