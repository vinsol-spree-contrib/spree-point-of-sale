module Spree
  module Stock
    class PosAvailabilityValidator < ActiveModel::Validator
      def validate(line_item)
        variant = line_item.variant
        stock_location = line_item.order.shipment.try(:stock_location)
        quantity_required = line_item.quantity - line_item.quantity_was.to_i
        if !stock_location || !stock_location.active? || !stock_location.store?
          line_item.errors[:stock_location] << 'No Active Store Associated'
        elsif !stock_location.can_supply?(quantity_required, variant)
          line_item.errors[:quantity] << 'Adding More Than Available'
        end
      end
    end
  end
end