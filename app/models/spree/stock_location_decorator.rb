module Spree
  StockLocation.class_eval do
    attr_accessible :store
    belongs_to :address

    before_validation :associate_address, :if => :store?

    scope :stores, where(:store => true)
    scope :not_store, where('store != ?', true)

    validates_associated :address, :if => :store?

    private
      def associate_address
        self.address = Spree::Address.where(:firstname => name, :lastname => '(Store)', :state_id => state_id, :country_id => country_id, :address1 => address1, :address2 => address2, :phone => phone, :zipcode => zipcode, :city => city).first_or_initialize
      end
  end
end