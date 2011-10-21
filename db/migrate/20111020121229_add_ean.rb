class AddEan < ActiveRecord::Migration
  def up
    add_column :variants, :ean, :string    
  end

  def down
    remove_column :variants, :ean
  end
end
