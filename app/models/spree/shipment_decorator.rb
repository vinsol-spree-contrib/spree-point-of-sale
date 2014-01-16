Spree::Shipment.class_eval do
  before_save :udpate_order_addresses_from_stock_location, :if => ["order.is_pos?", "stock_location_id.present?", :stock_location_id_changed? ]
  validate :empty_inventory, :if => ["order.is_pos?", "stock_location_id.present?", :stock_location_id_changed? ] 

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

  private

  def empty_inventory
    errors[:base] = "Inventory Units assigned for the order. Please remove them to change stock location" if inventory_units.present? 
  end

  def udpate_order_addresses_from_stock_location
    order.bill_address = order.ship_address = stock_location.address
    order.save
  end
end