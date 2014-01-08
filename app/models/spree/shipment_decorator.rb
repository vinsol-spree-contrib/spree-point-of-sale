Spree::Shipment.class_eval do

  def finalize_pos
    self.state = "delivered"
    inventory_units.each &:ship!
    self.save
    update_delivered_at
  end

end