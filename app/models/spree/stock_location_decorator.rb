module Spree
  StockLocation.class_eval do
    belongs_to :address

    before_validation :associate_address

    scope :stores, -> { where(store: true) }
    scope :not_store, -> { where.not(store: true) }

    validates_associated :address

    def can_supply?(quantity, variant)
      quantity <= stock_items.find_by(variant_id: variant.id).count_on_hand
    end

    def active_store?
      active? && store?
    end

    private
      def associate_address
        if respond_to?(:state_id) && store?
          self.address = Spree::Address.find_or_initialize_by(firstname: name,
            lastname: '(Store)', state_id: state_id, country_id: country_id,
            address1: address1, address2: address2, phone: phone, zipcode: zipcode,
            city: city)
        end
      end
  end
end
