Spree::Shipment.class_eval do
  before_save :udpate_order_addresses_from_stock_location, if: :stock_location_changed?
  validate :empty_inventory

  def finalize_pos
    self.state = 'shipped'
    inventory_units.each &:ship!
    self.save
    touch :delivered_at
  end

  def self.create_shipment_for_pos_order
    shipment = new
    shipment.stock_location = Spree::StockLocation.stores.active.first
    shipment.shipping_methods << Spree::ShippingMethod.find_by(name: SpreePos::Config[:pos_shipping])
    shipment.save!
  end

  private

    def stock_location_changed?
      order.is_pos? && stock_location_id.present? && stock_location_id_changed?
    end

    def empty_inventory
      if(order.is_pos? && stock_location_changed? && inventory_units.present?)
        errors.add(:base, Spree.t(:empty_inventory))
      end
    end

    def udpate_order_addresses_from_stock_location
      order.bill_address = order.ship_address = stock_location.address
      order.save
    end
end
