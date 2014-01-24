Spree::LineItem.class_eval do
  validates_with Spree::Stock::PosAvailabilityValidator, :if => "order.is_pos?"

  #remove the validation of Spree::Stock::Avilability and then re assign it to be for only non-pos orders
  _validators[nil].reject! { |v| v.class == Spree::Stock::AvailabilityValidator }
  _validate_callbacks.reject! { |c| c.raw_filter.class == Spree::Stock::AvailabilityValidator }

  validates_with Spree::Stock::AvailabilityValidator, :unless => "order.is_pos?"
end