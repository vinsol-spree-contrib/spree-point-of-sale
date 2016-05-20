Spree::LineItem.class_eval do
  validates_with Spree::Stock::PosAvailabilityValidator, if: -> { order.is_pos? }
end
