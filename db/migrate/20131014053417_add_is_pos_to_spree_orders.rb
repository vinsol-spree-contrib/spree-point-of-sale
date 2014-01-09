class AddIsPosToSpreeOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :is_pos, :boolean, :default => false
    add_index :spree_orders, :is_pos
  end
end
