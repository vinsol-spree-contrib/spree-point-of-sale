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
     Spree::Variant.find @id
  end

  def price= p
    @price = p.round(2)
  end
  
  def discount d
    dis = d.to_f
    if dis == 0.0
      reset_price
    else
      @price =  ((100.0 - dis) * @price / 100.0).round(2)
    end
  end
  def reset_price
    self.price = variant.price
  end
  
  def no_tax_price
    (self.price / (1  + variant.product.effective_tax_rate)).round(2)
  end
end
