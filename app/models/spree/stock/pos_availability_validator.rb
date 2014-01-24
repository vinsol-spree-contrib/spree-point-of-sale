module Spree
  module Stock
    class PosAvailabilityValidator < ActiveModel::Validator
      def validate(line_item)
        @variant = line_item.variant
        @stock_location = line_item.order.shipment.stock_location
        @stock_item = @stock_location.stock_items.where(:variant_id => @variant.id).first
        if ((line_item.quantity - (line_item.quantity_was || 0 )) > @stock_item.count_on_hand)
          line_item.errors[:quantity] << 'Adding More Than Available'
        end
      end
    end
  end
end