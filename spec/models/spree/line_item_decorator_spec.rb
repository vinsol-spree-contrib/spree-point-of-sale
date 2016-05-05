require 'spec_helper'

describe Spree::LineItem do
  describe 'validations' do
    it 'validates through Spree::Stock::PosAvailabilityValidator for pos orders' do
      subject.class.validators.map(&:class).include? Spree::Stock::PosAvailabilityValidator
    end
  end
end
