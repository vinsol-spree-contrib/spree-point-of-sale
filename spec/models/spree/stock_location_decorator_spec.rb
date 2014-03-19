require 'spec_helper'

describe Spree::StockLocation do
  it { should allow_mass_assignment_of :store }
  it { should belong_to :address }

  let(:country) { Spree::Country.create!(:name => 'mk_country', :iso_name => "mk") }
  let(:state) { country.states.create!(:name => 'mk_state') }
  let(:store) { Spree::StockLocation.create!(:name => 'store', :store => true, :address1 => "home", :address2 => "town", :city => "delhi", :zipcode => "110034", :country_id => country.id, :state_id => state.id, :phone => "07777676767") }
  let(:stock_location) { Spree::StockLocation.create!(:name => 'stock', :address1 => "home", :address2 => "town", :city => "delhi", :zipcode => "110034", :country_id => country.id, :state_id => state.id, :phone => "07777676767") }
  let(:shipping_category) { Spree::ShippingCategory.create!(:name => 'test-shipping') }

  context 'scopes' do
    it 'stores' do
      Spree::StockLocation.stores.should include(store)
      Spree::StockLocation.stores.should_not include(stock_location)
    end

    it 'not store' do
      Spree::StockLocation.not_store.should include(stock_location)
      Spree::StockLocation.not_store.should_not include(store)
    end
  end

  describe 'associate_address' do
    before do
      @new_store = Spree::StockLocation.create!(:name => 'new-store', :store => true, :address1 => "home", :address2 => "town", :city => "delhi", :zipcode => "110034", :country_id => country.id, :state_id => state.id, :phone => "07777676767")
    end

    it { Spree::Address.where(:firstname => @new_store.name, :lastname => '(Store)', :state_id => @new_store.state_id, :country_id => @new_store.country_id, :address1 => @new_store.address1, :address2 => @new_store.address2, :phone => @new_store.phone, :zipcode => @new_store.zipcode, :city => @new_store.city).should_not be_blank }
  end

  context 'validations' do
    describe 'associate address' do
      before do
        @invalid_store = Spree::StockLocation.new(:name => 'invalid-store')
        @invalid_store.address = Spree::Address.create
        @invalid_store.save
      end

      it { @invalid_store.errors[:address].should eq(['is invalid']) }
    end
  end

  describe '#can_supply?' do
    before do
      @product = Spree::Product.create!(:name => 'test-product', :price => 10, :shipping_category_id => shipping_category.id)
      @variant = @product.master
      @stock_item = store.stock_items.where(:variant_id => @variant.id).first
      @stock_item.update_column(:count_on_hand, 2)
    end

    it { store.can_supply?(1,@variant).should be_true }
    it { store.can_supply?(2,@variant).should be_true }
    it { store.can_supply?(3,@variant).should be_false }
  end
end