require 'spec_helper'

describe Spree::Order do
  [:state, :is_pos, :completed_at, :payment_state].each do |attribute|
    it { should allow_mass_assignment_of attribute }
  end

  before do
    @order = Spree::Order.create!
    @variant = Spree::Variant.new
    @shipment = @order.shipments.new
    @line_item = @order.line_items.new(:quantity => 1)
    @line_item.variant = @variant
    @payment = mock_model(Spree::Payment)
    @payments = [@payment]
    @payments.stub(:delete_all).and_return(true)
    @order.stub(:payments).and_return(@payments)
    @content = Spree::OrderContents.new(@order)
    @order.stub(:contents).and_return(@content)
    @content.stub(:remove).with(@variant, 1, @shipment).and_return(true)
  end

  describe '#clean!' do
    it { @payments.should_receive(:delete_all).and_return(true) }
    it { @line_item.should_receive(:variant).and_return(@variant) }
    it { @line_item.should_receive(:quantity).and_return(1) }
    it { @content.should_receive(:remove).with(@variant, 1, @shipment).and_return(true) }
    
    after { @order.clean! }
  end

  describe '#complete_via_pos' do
    before do
      @order.stub(:create_tax_charge!).and_return(true)
      @order.stub(:pending_payments).and_return(@payments)
      @payment.stub(:capture!).and_return(true)
      @shipment.stub(:finalize_pos).and_return(true)
      @order.stub(:deliver_order_confirmation_email).and_return(true)
      @order.stub(:save!).and_return(true)
    end

    it { @order.should_receive(:touch).with(:completed_at) }
    it { @order.should_receive(:create_tax_charge!).and_return(true) }
    it { @order.should_receive(:pending_payments).and_return(@payments) }
    it { @payment.should_receive(:capture!).and_return(true) }
    it { @shipment.should_receive(:finalize_pos).and_return(true) }
    it { @order.should_receive(:deliver_order_confirmation_email).and_return(true) }
    it { @order.stub(:save!).and_return(true) }
    
    after { @order.complete_via_pos }
  end

  describe '#assign_shipment_for_pos' do
    context '#is_pos?' do
      before do
        @order.stub(:is_pos?).and_return(true)
        @stock_location = mock_model(Spree::StockLocation)
        Spree::StockLocation.stub(:active).and_return([@stock_location])
        @pos_shipping_method = mock_model(Spree::ShippingMethod)
        Spree::ShippingMethod.stub(:where).and_return([@pos_shipping_method])
        @order.stub_chain(:shipments, :build).and_return(@shipment)
        @shipment.stub(:save!).and_return(true)
      end

      describe 'method calls' do
        it { @order.should_receive(:is_pos?).and_return(true) }
        it { @shipment.should_receive(:save!).and_return(true) }        

        after { @order.assign_shipment_for_pos }
      end

      describe 'assigns' do
        before { @order.assign_shipment_for_pos }
        
        it { @shipment.shipping_methods.should eq([@pos_shipping_method]) }
        it { @shipment.stock_location.should eq(@stock_location) }
      end
    end

    context '#is_pos? false' do
      before { @order.stub(:is_pos?).and_return(false) }
      
      describe 'method calls' do
        it { @order.should_receive(:is_pos?).and_return(false) }
        it { Spree::ShippingMethod.should_not_receive(:where) }
        it { Spree::StockLocation.should_not_receive(:active) }        

        after { @order.assign_shipment_for_pos }
      end      
    end
  end
end