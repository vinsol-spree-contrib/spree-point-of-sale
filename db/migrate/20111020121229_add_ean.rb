class AddEan < ActiveRecord::Migration
  def up
    add_column :spree_variants, :ean, :string    
  end

  def down
    remove_column :spree_variants, :ean
  end
end
