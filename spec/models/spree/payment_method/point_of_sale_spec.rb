require 'spec_helper'

describe Spree::PaymentMethod::PointOfSale do
  let(:pending_payment) { mock_model(Spree::Payment, state: 'pending') }
  let(:complete_payment) { mock_model(Spree::Payment, state: 'complete') }
  let(:void_payment) { mock_model(Spree::Payment, state: 'void') }
  before { @point_of_sale_payment = Spree::PaymentMethod::PointOfSale.new }
  it { expect(@point_of_sale_payment.actions).to eq(["capture", "void"]) }
  it { expect(@point_of_sale_payment.can_capture?(pending_payment)).to be_truthy }
  it { expect(@point_of_sale_payment.can_capture?(complete_payment)).to be_falsey }
  it { expect(@point_of_sale_payment.can_void?(pending_payment)).to be_truthy }
  it { expect(@point_of_sale_payment.can_void?(void_payment)).to be_falsey }
  it { expect(@point_of_sale_payment.source_required?).to be_falsey }
  it { expect(@point_of_sale_payment.payment_profiles_supported?).to be_falsey }

  it 'voids a payment' do
    expect(ActiveMerchant::Billing::Response).to receive(:new).with(true, "", {}, {}).and_return(true)
    @point_of_sale_payment.void
  end

  it 'captures a payment' do
    expect(ActiveMerchant::Billing::Response).to receive(:new).with(true, "", {}, {}).and_return(true)
    @point_of_sale_payment.capture
  end
end
