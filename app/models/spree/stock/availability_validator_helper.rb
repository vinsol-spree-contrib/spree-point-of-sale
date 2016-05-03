module Spree
  module Stock
    module AvailabilityValidatorHelper

      def validate(line_item)
        return if line_item.order.is_pos?
        super
      end

    end
  end
end
