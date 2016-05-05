require 'spec_helper'

describe Spree::Variant do
  let(:shipping_category) { Spree::ShippingCategory.create!(name: 'test-shipping') }
  let(:product) { Spree::Product.create!( name: 'new_product', price: 10, available_on: 'Fri, 19 Jul 2013 08:11:06 UTC +00:00', shipping_category_id: shipping_category.id ) }

  describe 'scopes' do
    describe 'available_at_stock_location' do
      before do
        @variant = product.variants.create!(sku: "M12343")
        @unavailable_variant = product.variants.create!(sku: "M12344")
  
        @stock_location1 = Spree::StockLocation.create!(name: 'test_location')
        @stock_location2 = Spree::StockLocation.create!(name: 'test_location')
      
        @stock_item1 = @stock_location1.stock_items.where(variant_id: @unavailable_variant.id).first
        @stock_item1.send(:count_on_hand=, 0)
        @stock_item1.save!
        @stock_item2 = @stock_location1.stock_items.where(variant_id: @variant.id).first
        @stock_item2.send(:count_on_hand=, 2)
        @stock_item2.save!
        @stock_item3 = @stock_location2.stock_items.where(variant_id: @unavailable_variant.id).first
        @stock_item3.send(:count_on_hand=, 3)
        @stock_item3.save!
      end
      
      it { expect(Spree::Variant.available_at_stock_location(@stock_location1.id)).to include(@variant) }
      it { expect(Spree::Variant.available_at_stock_location(@stock_location1.id)).not_to include(@unavailable_variant) }
    end
  end
end
