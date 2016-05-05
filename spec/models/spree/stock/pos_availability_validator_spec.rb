require 'spec_helper'

describe Spree::Stock::PosAvailabilityValidator do
  let(:country) { Spree::Country.create!(name: 'mk_country', iso_name: "mk") }
  let(:state) { country.states.create!(name: 'mk_state') }
  let(:store) { Spree::StockLocation.create!(name: 'store', store: true, address1: "home", address2: "town", city: "delhi", zipcode: "110034", country_id: country.id, state_id: state.id, phone: "07777676767") }
  let(:shipping_category) { Spree::ShippingCategory.create!(name: 'test-shipping') }

  before do
    @order = Spree::Order.create!(is_pos: true)
    @product = Spree::Product.create!(name: 'test-product', price: 10, shipping_category: shipping_category)
    @variant = @product.master
    @line_item = @order.line_items.build(variant_id: @variant.id, quantity: 3)
    @line_item.price = @product.price
    @shipment = @order.shipments.create(stock_location: store)
    allow(@line_item).to receive(:order).and_return(@order)
    allow(@order).to receive(:shipments).and_return([@shipment])
  end

  describe 'ensures stock location' do
    it 'presence' do
      @order.shipments.last.stock_location = nil
      expect(@line_item.order.pos_shipment.stock_location).to be_nil
      @line_item.save
      expect(@line_item.errors[:stock_location]).to eq(['No Active Store Associated'])
    end

    it 'as active' do
      store.update_attributes(active: false, store: true)
      allow(@shipment).to receive(:stock_location).and_return(store)
      @line_item.save
      expect(@line_item.errors[:stock_location]).to eq(['No Active Store Associated'])
    end

    it 'as store' do
      store.update_attributes(active: true, store: false)
      allow(@shipment).to receive(:stock_location).and_return(store)
      @line_item.save
      expect(@line_item.errors[:stock_location]).to eq(['No Active Store Associated'])
    end

    it 'as store' do
      store.update_attributes(active: true, store: true)
      allow(@shipment).to receive(:stock_location).and_return(store)
      @line_item.save
      expect(@line_item.errors[:stock_location]).to be_blank
    end
  end

  describe 'checks for supply' do
    before do
      store.update_attributes(active: true, store: true)
      allow(@shipment).to receive(:stock_location).and_return(store)
    end

    it 'adds error if cant supply' do
      @line_item.save
      expect(@line_item.errors[:quantity]).to eq(['Adding More Than Available'])
    end

    it 'no error if can supply' do
      store.stock_items.update_all(count_on_hand: 4)
      @line_item.save!
      expect(@line_item.errors[:quantity]).to be_blank
    end

    it 'finds out quantity difference' do
      expect(@line_item).to receive(:quantity_was).and_return(nil)
      @line_item.save
    end
  end
end 
