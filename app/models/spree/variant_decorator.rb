Spree::Variant.class_eval do
  scope :available_at_stock_location, ->(stock_location_id) { active.joins(:stock_items).where('spree_stock_items.count_on_hand > 0 AND spree_stock_items.stock_location_id = ?', stock_location_id)}
end
