Variant.class_eval do

  def tax_price
    self.price * (1 + self.product.effective_tax_rate)
  end
  
end
