class PosItem
  attr :id , true 
  attr :price , true 
  attr :quantity , true
  
  def initialize var 
    @id  = var.id
    @quantity = 0
    reset_price
  end
  
  def variant
     Variant.find @id
  end

  def price= p
    @price = p.round(2, BigDecimal::ROUND_HALF_UP)
  end
  
  def discount d
    dis = d.to_f
    if dis == 0.0
      reset_price
    else
      @price =  (100.0 - dis) * @price / 100.0 
    end
  end
  def reset_price
    self.price = variant.tax_price
  end
  
  def no_tax_price
    self.price / (1  + variant.product.effective_tax_rate)
  end
end
