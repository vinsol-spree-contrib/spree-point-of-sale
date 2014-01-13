class AddCardNameToSpreePayments < ActiveRecord::Migration
  def change
    add_column :spree_payments, :card_name, :string
  end
end
