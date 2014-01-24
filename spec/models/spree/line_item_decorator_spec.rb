require 'spec_helper'

describe Spree::LineItem do
  describe 'validations' do
    it 'validates through Spree::Stock::PosAvailabilityValidator for pos orders' do
      subject._validators[nil].select do |validator|
        validator.class == Spree::Stock::PosAvailabilityValidator && validator.options[:if] == "order.is_pos?"
      end.should_not be_blank
    end

    it 'removes validation through Spree::Stock::AvailabilityValidator' do
      subject._validators[nil].select do |validator|
        validator.class == Spree::Stock::AvailabilityValidator && validator.options.blank?
      end.should be_blank
    end

    it 'removes callback for Spree::Stock::AvailabilityValidator' do
      subject._validate_callbacks.select do |callback|
        callback.raw_filter.class == Spree::Stock::AvailabilityValidator && callback.options.blank?
      end.should be_blank
    end

    it 'validates through Spree::Stock::AvailabilityValidator for non pos orders' do
      subject._validators[nil].select do |validator|
        validator.class == Spree::Stock::AvailabilityValidator && validator.options[:unless] == "order.is_pos?"
      end.should_not be_blank
    end
  end
end