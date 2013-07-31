class AddStoreAndAddressIdInSpreeStockLocations < ActiveRecord::Migration
  def change
    add_column :spree_stock_locations, :store, :boolean, :default => false
    add_column :spree_stock_locations, :address_id, :integer
    add_index :spree_stock_locations, :store, :name => "index_spree_stock_locations_on_store"
    add_index :spree_stock_locations, :address_id, :name => "index_spree_stock_locations_on_address_id"
  end
end
