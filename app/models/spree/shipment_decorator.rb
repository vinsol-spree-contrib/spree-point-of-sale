Spree::Shipment.class_eval do

  def finalize_pos
    self.state = "shipped"
    inventory_units.each &:ship!
    self.save
    touch :delivered_at
  end

end