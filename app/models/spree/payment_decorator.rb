Spree::Payment.class_eval do
  validates :payment_method, presence: true, if: -> { order.is_pos? }
  validates :card_name, presence: true, if: :check_for_card_name?
  validate :no_card_name

  private
    def no_card_name
      if payment_method.present? && !payment_method_with_card_present? && card_name.present?
        errors.add(:base, Spree.t(:no_card_name))
      end
    end

    def check_for_card_name?
      payment_method && order.is_pos? && payment_method_with_card_present?
    end

    def payment_method_with_card_present?
      payment_method.name.scan(/card/i).present?
    end
end
