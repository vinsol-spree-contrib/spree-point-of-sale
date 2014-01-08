module Spree
  StockLocation.class_eval do
    attr_accessible :store
    belongs_to :address

    before_validation :associate_address

    scope :stores, where(:store => true)
    scope :not_store, where('store != ?', true)

    validates_associated :address

    private
      def associate_address
        #the if condition is just to avoid breaking of migrations due to validation of fields not added yet, it can be removed post deploy/setup
        self.address = Spree::Address.where(:firstname => name, :lastname => '(Store)', :state_id => state_id, :country_id => country_id, :address1 => address1, :address2 => address2, :phone => phone, :zipcode => zipcode, :city => city).first_or_initialize if respond_to?(:state_id) && store?
      end
  end
end