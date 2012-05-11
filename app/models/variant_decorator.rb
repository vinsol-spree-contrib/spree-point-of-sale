Spree::Variant.class_eval do

  def tax_price
    (self.price * (1 + self.product.effective_tax_rate)).round(2, BigDecimal::ROUND_HALF_UP)
  end
  
end

puts "LOADED"