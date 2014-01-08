require 'spec_helper'

describe Spree::PaymentMethod::PointOfSale do
  let(:pending_payment) { mock_model(Spree::Payment, :state => 'pending') }
  let(:complete_payment) { mock_model(Spree::Payment, :state => 'complete') }
  let(:void_payment) { mock_model(Spree::Payment, :state => 'void') }
  before { @point_of_sale_payment = Spree::PaymentMethod::PointOfSale.new }
  it { @point_of_sale_payment.actions.should eq(["capture", "void"]) }
  it { @point_of_sale_payment.can_capture?(pending_payment).should be_true }
  it { @point_of_sale_payment.can_capture?(complete_payment).should be_false }
  it { @point_of_sale_payment.can_void?(pending_payment).should be_true }
  it { @point_of_sale_payment.can_void?(void_payment).should be_false }
  it { @point_of_sale_payment.source_required?.should be_false }
  it { @point_of_sale_payment.payment_profiles_supported?.should be_false }

  it 'voids a payment' do
    ActiveMerchant::Billing::Response.should_receive(:new).with(true, "", {}, {}).and_return(true)
    @point_of_sale_payment.void
  end

  it 'captures a payment' do
    ActiveMerchant::Billing::Response.should_receive(:new).with(true, "", {}, {}).and_return(true)
    @point_of_sale_payment.capture
  end
end