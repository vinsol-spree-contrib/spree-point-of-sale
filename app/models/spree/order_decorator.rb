Spree::Order.class_eval do
  attr_accessible :state, :is_pos, :completed_at, :payment_state

  scope :pos, where(:is_pos => true)
  scope :unpaid, where("payment_state != 'paid'")
  scope :pending_pos_order, ->{ pos.unpaid }

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

  def save_payment_for_pos(payment_method_id, card_name = nil)
    payments.delete_all
    payment = payments.create(:amount => total, :payment_method_id => payment_method_id, :card_name => card_name)
  end

  def associate_user_for_pos(new_user_email)
    associate_with_user = Spree::User.where(:email => new_user_email).first || Spree::User.create_with_random_password(new_user_email)
    self.email = new_user_email if associate_with_user.valid?
    associate_with_user
  end
end