Spree::Order.class_eval do
  attr_accessible :state, :is_pos, :completed_at, :payment_state
  def clean!
    payments.delete_all
    line_items.each { |line_item| contents.remove(line_item.variant, line_item.quantity, shipment) }
  end

  def complete_via_pos
    touch :completed_at
    create_tax_charge!
    save!
    pending_payments.first.capture!
    shipments.each { |shipment|  shipment.finalize_pos }
    deliver_order_confirmation_email
  end

  def assign_shipment_for_pos 
    if is_pos?
      order_shipment = shipments.build
      order_shipment.stock_location = Spree::StockLocation.active.first
      order_shipment.shipping_methods << Spree::ShippingMethod.where(:name => SpreePos::Config[:pos_shipping]).first
      order_shipment.save!
    end
  end
end