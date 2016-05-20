require 'spec_helper'

describe Spree::Shipment do
  let(:order) { Spree::Order.create! }
  let(:flat_rate_calculator) { Spree::Calculator::Shipping::FlatRate.create! }
  let(:country) { Spree::Country.create!(name: 'mk_country', iso_name: "mk") }
  let(:state) { country.states.create!(name: 'mk_state') }
  let(:store) { Spree::StockLocation.create!(name: 'store', store: true, address1: "home", address2: "town", city: "delhi", zipcode: "110034", country_id: country.id, state_id: state.id, phone: "07777676767") }
  let(:second_store) { Spree::StockLocation.create!(name: 'second store', store: true, address1: "home", address2: "town", city: "delhi", zipcode: "110034", country_id: country.id, state_id: state.id, phone: "07777676767") }

  before do
    @shipment = Spree::Shipment.new
  end

  describe '#finalize_pos' do
    before do
      @inventory_unit = mock_model(Spree::InventoryUnit)
      allow(@inventory_unit).to receive(:ship!).and_return(true)
      @inventory_units = [@inventory_unit]
      allow(@shipment).to receive(:inventory_units).and_return(@inventory_units)
      allow(@shipment).to receive(:state=).with('shipped').and_return(true)
      allow(@shipment).to receive(:touch).with(:delivered_at).and_return(true)
      allow(@shipment).to receive(:save).and_return(true)
    end

    it { expect(@shipment).to receive(:state=).with('shipped').and_return(true) }
    it { expect(@shipment).to receive(:inventory_units).and_return(@inventory_units) }
    it { expect(@inventory_unit).to receive(:ship!).and_return(true) }
    it { expect(@shipment).to receive(:touch).with(:delivered_at).and_return(true) }
    it { expect(@shipment).to receive(:save).and_return(true) }
    after { @shipment.finalize_pos }
  end

  describe 'create_shipment_for_pos_order' do
    before do
      shipping_category = Spree::ShippingCategory.create! name: 'test-category'
      @shipping_method = Spree::ShippingMethod.new(name: 'test-method') { |method| method.calculator = flat_rate_calculator }
      @shipping_method.shipping_categories << shipping_category
      @shipping_method.save!
      SpreePos::Config[:pos_shipping] = @shipping_method.name
      store.save
    end

    it 'looks for the first active store' do
      expect(Spree::StockLocation).to receive(:stores).and_return(Spree::StockLocation)
      expect(Spree::StockLocation).to receive(:active).and_return([store])
      order.shipments.create_shipment_for_pos_order
    end

    it 'looks for the config shipping method' do
      expect(Spree::ShippingMethod).to receive(:find_by).with(name: SpreePos::Config[:pos_shipping]).and_return([@shipping_method])
      order.shipments.create_shipment_for_pos_order
    end

    describe 'creates a new shipment for the order' do
      before { order.shipments.create_shipment_for_pos_order }
      it { expect(order.shipments.count).to eq(1) }
      it { expect(order.shipments).not_to be_blank }
      it { expect(order.shipments.first.shipping_method).to eq(@shipping_method) }
      it { expect(order.shipments.first.stock_location).to eq(store) }
    end
  end

  describe 'validate empty inventory' do
    before do
      @order = Spree::Order.create!
      @shipment = @order.shipments.create!(stock_location: store)
      @shipment.stock_location = store
      @shipment.save!
      @inventory_unit = @shipment.inventory_units.create!
    end

    context 'not a pos order' do
      it 'no error on shipment' do
        @shipment.reload
        @shipment.save
        expect(@shipment.errors).to be_blank
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

        it { expect(@shipment.errors[:base]).to be_blank }
      end

      context 'stock location present and changed' do
        before do
          @shipment.stock_location = second_store
          @shipment.save
          @shipment.reload
          @shipment.stock_location = store
        end

        it { expect(@shipment.errors[:base]).to eq(["Inventory Units assigned for the order. Please remove them to change stock location"]) }
      end

      context 'stock_location not present' do
        before do
          @shipment.stock_location = nil
          @shipment.save
        end

        it { expect(@shipment.errors[:base]).to be_blank }
      end
    end
  end

  describe 'udpate_order_addresses_from_stock_location' do
    before do
      @order = Spree::Order.create!
      @shipment = @order.shipments.create!(stock_location: store)
      @shipment.stock_location = store
      @shipment.save!
    end

    context 'not a pos order' do
      before { @order.reload }

      it { expect(@order.ship_address).to be_nil }
      it { expect(@order.bill_address).to be_nil }
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

        it { expect(@order.ship_address).to be_nil }
        it { expect(@order.bill_address).to be_nil }
      end

      context 'stock location present and changed' do
        before do
          @shipment.stock_location = second_store
          @shipment.save!
          @shipment.reload
          @shipment.stock_location = store
          @shipment.save!
          @order.reload
        end

        it { expect(@order.ship_address).to eq(store.address) }
        it { expect(@order.bill_address).to eq(store.address) }
      end
    end
  end
end
