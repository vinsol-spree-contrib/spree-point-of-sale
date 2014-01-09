Spree::Payment.class_eval do
  attr_accessible :card_name
  validates :payment_method, :presence => true, :if => ["order.is_pos?"]
  validates :card_name, :presence => true, :if => [:payment_method, "order.is_pos? && payment_method.name.scan(/card/i).present?"]
  validate :no_card_name, :if => [:payment_method, "payment_method.name.scan(/card/i).blank?"]

  def no_card_name
    errors.add(:base, "No card name to be saved with this payment") if card_name.present?
  end
end