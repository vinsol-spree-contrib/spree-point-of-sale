module Spree
  module Stock
    AvailabilityValidator.class_eval do

      prepend AvailabilityValidatorHelper

    end
  end
end
