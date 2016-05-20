module Spree
  module Stock
    class PosAvailabilityValidator < ActiveModel::Validator

      def validate(line_item)
        stock_location = line_item.order.pos_shipment.try(:stock_location)
        quantity_required = line_item.quantity - line_item.quantity_was.to_i

        if !stock_location.try(:active_store?)
          line_item.errors.add(:stock_location, Spree.t(:no_active_store))
        elsif !stock_location.can_supply?(quantity_required, line_item.variant)
          line_item.errors.add(:quantity, Spree.t(:quantity_unavailable))
        end
      end

    end
  end
end
