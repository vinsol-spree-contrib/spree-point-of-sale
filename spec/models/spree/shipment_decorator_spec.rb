require 'spec_helper'

describe Spree::Shipment do
  let(:order) { Spree::Order.create! }
  let(:flat_rate_calculator) { Spree::Calculator::Shipping::FlatRate.create! }
  let(:country) { Spree::Country.create!(:name => 'mk_country', :iso_name => "mk") }
  let(:state) { country.states.create!(:name => 'mk_state') }
  let(:store) { Spree::StockLocation.create!(:name => 'store', :store => true, :address1 => "home", :address2 => "town", :city => "delhi", :zipcode => "110034", :country_id => country.id, :state_id => state.id, :phone => "07777676767") }
  
  before do
    @shipment = Spree::Shipment.new
  end

  describe '#finalize_pos' do
    before do
      @inventory_unit = mock_model(Spree::InventoryUnit)
      @inventory_unit.stub(:ship!).and_return(true)
      @inventory_units = [@inventory_unit]
      @shipment.stub(:inventory_units).and_return(@inventory_units)
      @shipment.stub(:state=).with('shipped').and_return(true)
      @shipment.stub(:touch).with(:delivered_at).and_return(true)
      @shipment.stub(:save).and_return(true)
    end

    it { @shipment.should_receive(:state=).with('shipped').and_return(true) }
    it { @shipment.should_receive(:inventory_units).and_return(@inventory_units) }
    it { @inventory_unit.should_receive(:ship!).and_return(true) }
    it { @shipment.should_receive(:touch).with(:delivered_at).and_return(true) }
    it { @shipment.should_receive(:save).and_return(true) }
    after { @shipment.finalize_pos }
  end

  describe 'create_shipment_for_pos_order' do
    before do
      shipping_category = Spree::ShippingCategory.create! :name => 'test-category'
      @shipping_method = Spree::ShippingMethod.new(:name => 'test-method') { |method| method.calculator = flat_rate_calculator }
      @shipping_method.shipping_categories << shipping_category
      @shipping_method.save!
      SpreePos::Config[:pos_shipping] = @shipping_method.name
      store.save
    end
    
    it 'looks for the first active store' do
      Spree::StockLocation.should_receive(:stores).and_return(Spree::StockLocation)
      Spree::StockLocation.should_receive(:active).and_return([store])
      order.shipments.create_shipment_for_pos_order
    end

    it 'looks for the config shipping method' do
      Spree::ShippingMethod.should_receive(:where).with(:name => SpreePos::Config[:pos_shipping]).and_return([@shipping_method])
      order.shipments.create_shipment_for_pos_order
    end

    describe 'creates a new shipment for the order' do
      before { order.shipments.create_shipment_for_pos_order }
      it { order.shipments.count.should eq(1) }
      it { order.shipments.should_not be_blank }
      it { order.shipments.first.shipping_method.should eq(@shipping_method) }
      it { order.shipments.first.stock_location.should eq(store) }
    end
  end

  describe 'validate empty inventory' do
    before do
      @order = Spree::Order.create!
      @shipment = @order.shipments.create!
      @shipment.stock_location = store
      @shipment.save!
      @inventory_unit = @shipment.inventory_units.create!
    end

    context 'not a pos order' do
      it 'no error on shipment' do
        @shipment.reload
        @shipment.save
        @shipment.errors.should be_blank
      end
    end

    context 'pos order' do
      before { @order.update_column(:is_pos, true) }

      context 'stock location present and not changed' do
        before do
          @shipment.reload
          @shipment.stock_location = store
          @shipment.save
        end

        it { @shipment.errors[:base].should be_blank }
      end

      context 'stock location present and changed' do
        before do
          @shipment.stock_location = nil
          @shipment.save!
          @shipment.reload
          @shipment.stock_location = store
          @shipment.save
        end

        it { @shipment.errors[:base].should eq(["Inventory Units assigned for the order. Please remove them to change stock location"]) }
      end

      context 'stock_location not present' do
        before do
          @shipment.stock_location = nil
          @shipment.save
        end

        it { @shipment.errors[:base].should be_blank }
      end
    end
  end

  describe 'udpate_order_addresses_from_stock_location' do
    before do
      @order = Spree::Order.create!
      @shipment = @order.shipments.create!
      @shipment.stock_location = store
      @shipment.save!
    end

    context 'not a pos order' do
      before { @order.reload }

      it { @order.ship_address.should be_nil }
      it { @order.bill_address.should be_nil }
    end

    context 'pos order' do
      before { @order.update_column(:is_pos, true) }

      context 'stock location present and not changed' do
        before do
          @shipment.reload
          @shipment.stock_location = store
          @shipment.save!
          @order.reload
        end

        it { @order.ship_address.should be_nil }
        it { @order.bill_address.should be_nil }
      end

      context 'stock location present and changed' do
        before do
          @shipment.stock_location = nil
          @shipment.save!
          @shipment.reload
          @shipment.stock_location = store
          @shipment.save!
          @order.reload
        end

        it { @order.ship_address.should eq(store.address) }
        it { @order.bill_address.should eq(store.address) }
      end

      context 'stock_location not present' do
        before do
          @shipment.stock_location = nil
          @shipment.save!
          @order.reload
        end

        it { @order.ship_address.should be_nil }
        it { @order.bill_address.should be_nil }
      end
    end
  end
end