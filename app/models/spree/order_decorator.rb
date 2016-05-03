Spree::Order.class_eval do

  scope :pos, -> { where(is_pos: true) }
  scope :unpaid, -> { where.not(payment_state: :paid) }
  scope :unpaid_pos_order, -> { pos.unpaid }

  self.whitelisted_ransackable_associations << 'product'
  self.whitelisted_ransackable_attributes << 'is_pos'

  def clean!
    payments.delete_all
    line_items.each { |_li| contents.remove(_li.variant, _li.quantity, { shipment: pos_shipment }) }
    #shipment is removed on removing all items, so initializing a new shipment
    assign_shipment_for_pos
  end

  def complete_via_pos
    touch :completed_at
    create_tax_charge!
    save!
    pending_payments.first.capture! if pending_payments.first.present?
    shipments.each { |shipment|  shipment.finalize_pos }
    deliver_order_confirmation_email
  end

  def assign_shipment_for_pos
    shipments.create_shipment_for_pos_order if is_pos?
  end

  def save_payment_for_pos(payment_method_id, card_name = nil)
    payments.delete_all
    payment = payments.create(amount: total, payment_method_id: payment_method_id, card_name: card_name)
  end

  def associate_user_for_pos(new_user_email)
    associate_with_user = Spree::User.find_by(email: new_user_email) || Spree::User.create_with_random_password(new_user_email)
    self.email = new_user_email if associate_with_user.valid?
    associate_with_user
  end

  def pos_shipment
    shipments.last
  end
end
