Spree::Shipment.class_eval do

  def finalize_pos
    self.state = "shipped"
    inventory_units.each &:ship!
    self.save
    touch :delivered_at
  end

  def self.create_shipment_for_pos_order
    shipment = new
    shipment.stock_location = Spree::StockLocation.stores.active.first
    shipment.shipping_methods << Spree::ShippingMethod.where(:name => SpreePos::Config[:pos_shipping]).first
    shipment.save!
  end
end