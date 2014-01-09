require 'spec_helper'

describe Spree::Payment do
  it { should allow_mass_assignment_of :card_name }

  let(:payment_method) { Spree::PaymentMethod.create!(:name => 'test-method') }
  let(:card_payment_method) { Spree::PaymentMethod.create!(:name => 'card-payment')}
  let(:order) { Spree::Order.create! }
  context 'validations' do
    describe 'payment_method' do
      context 'pos_order' do
        before do
          order.stub(:is_pos?).and_return(true)
          @payment = Spree::Payment.new
          @payment.stub(:order).and_return(order)
          @payment.save
        end

        it { @payment.errors[:payment_method].should eq(["can't be blank"])}
      end

      context 'non pos_order' do
        before do
          order.stub(:is_pos?).and_return(false)
          @payment = Spree::Payment.new
          @payment.stub(:order).and_return(order)
          @payment.save
        end

        it { @payment.errors[:payment_method].should be_blank }
      end
    end

    describe 'card_name presence' do
      context 'without payment_method' do
        before do 
          order.stub(:is_pos?).and_return(true)
          @payment = Spree::Payment.new
          @payment.stub(:order).and_return(order)
          @payment.save
        end
        it { @payment.errors[:card_name].should be_blank }
      end

      context 'not pos order' do
        before do
          order.stub(:is_pos?).and_return(false)
          @payment = Spree::Payment.new(:payment_method_id => card_payment_method.id)
          @payment.stub(:order).and_return(order)
          @payment.save
        end
        it { @payment.errors[:card_name].should be_blank }
      end

      context 'non card payment method' do
        before do
          order.stub(:is_pos?).and_return(true)
          @payment = Spree::Payment.new(:payment_method_id => payment_method.id)
          @payment.stub(:order).and_return(order)
          @payment.save
        end
        it { @payment.errors[:card_name].should be_blank }
      end

      context 'pos order with card payment' do
        before do
          order.stub(:is_pos?).and_return(true)
          @payment = Spree::Payment.new(:payment_method_id => card_payment_method.id)
          @payment.stub(:order).and_return(order)
          @payment.save
        end
        it { @payment.errors[:card_name].should eq(["can't be blank"]) }
      end
    end

    describe 'card_name absence' do
      context 'without payment_method' do
        before do 
          @payment = Spree::Payment.new
          @payment.stub(:order).and_return(order)
          @payment.save
        end
        it { @payment.errors[:base].should be_blank }
      end

      context 'non card payment method' do
        context 'with card name' do
          before do
            @payment = Spree::Payment.new(:payment_method_id => payment_method.id, :card_name => "MasterCard")
            @payment.stub(:order).and_return(order)
            @payment.save
          end
          it { @payment.errors[:base].should eq(['No card name to be saved with this payment']) }
        end
        context 'no card name' do
          before do
            @payment = Spree::Payment.new(:payment_method_id => payment_method.id)
            @payment.stub(:order).and_return(order)
            @payment.save
          end
          it { @payment.errors[:base].should be_blank }
        end
      end

      context 'with card payment method' do
        before do
          @payment = Spree::Payment.new(:payment_method_id => card_payment_method.id)
          @payment.stub(:order).and_return(order)
          @payment.save
        end
        it { @payment.errors[:base].should be_blank }
      end
    end
  end
end