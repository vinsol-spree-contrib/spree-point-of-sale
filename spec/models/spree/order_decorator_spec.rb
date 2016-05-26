require 'spec_helper'

describe Spree::Order do
  let(:user) { mock_model(Spree::User, email: 'test-user@pos.com') }
  let(:flat_rate_calculator) { Spree::Calculator::Shipping::FlatRate.create! }
  let(:country) { Spree::Country.create!(name: 'mk_country', iso_name: "mk") }
  let(:state) { country.states.create!(name: 'mk_state') }
  let(:store) { Spree::StockLocation.create!(name: 'store', store: true, address1: "home", address2: "town", city: "delhi", zipcode: "110034", country_id: country.id, state_id: state.id, phone: "07777676767") }

  before do
    @order = Spree::Order.create!(is_pos: true)
    allow(@order).to receive(:total).and_return 100
    @variant = Spree::Variant.new
    @shipment = @order.shipments.new
    @line_item = @order.line_items.new(quantity: 1)
    @line_item.variant = @variant
    @payment = mock_model(Spree::Payment)
    @payments = [@payment]
    allow(@payments).to receive(:delete_all).and_return(true)
    allow(@order).to receive(:payments).and_return(@payments)
    @content = Spree::OrderContents.new(@order)
    allow(@order).to receive(:contents).and_return(@content)
    allow(@content).to receive(:remove).with(@variant, 1, { shipment: @shipment }).and_return(true)
    allow(@shipment).to receive(:stock_location).and_return store
  end

  context 'scopes' do
    before :each do
      @paid_order = Spree::Order.create!
      @paid_order.update_column(:total,100)
      @paid_order.update_column(:payment_state,'paid')
      @unpaid_pos_order = Spree::Order.create!(is_pos: true, payment_state: 'balance_due')
      @paid_pos_order = Spree::Order.create!(is_pos: true, payment_state: 'paid')
      @paid_pos_order.update_column(:payment_state,'paid')
      @unpaid_order = Spree::Order.create!(payment_state: 'balance_due')
    end

    it { expect(Spree::Order.pos).to match_array([@order, @unpaid_pos_order, @paid_pos_order]) }
    it { expect(Spree::Order.unpaid).to match_array([@unpaid_pos_order, @unpaid_order]) }
    it { expect(Spree::Order.unpaid_pos_order).to eq([@unpaid_pos_order]) }
  end

  describe '#clean!' do
    before { allow(@order).to receive(:assign_shipment_for_pos).and_return(true) }
    it { expect(@payments).to receive(:delete_all).and_return(true) }
    it { expect(@line_item).to receive(:variant).and_return(@variant) }
    it { expect(@line_item).to receive(:quantity).and_return(1) }
    it { expect(@content).to receive(:remove).with(@variant, 1, { shipment: @shipment }).and_return(true) }
    it { expect(@order).to receive(:assign_shipment_for_pos).and_return(true) }
    after { @order.clean! }
  end

  describe '#complete_via_pos' do
    before do
      allow(@order).to receive(:create_tax_charge!).and_return(true)
      allow(@order).to receive(:pending_payments).and_return(@payments)
      allow(@payment).to receive(:capture!).and_return(true)
      allow(@payment).to receive(:checkout?).and_return(true)
      allow(@shipment).to receive(:finalize_pos).and_return(true)
      allow(@order).to receive(:deliver_order_confirmation_email).and_return(true)
      allow(@order).to receive(:save!).and_return(true)
    end

    it { expect(@order).to receive(:touch).with(:completed_at) }
    it { expect(@order).to receive(:create_tax_charge!).and_return(true) }
    it { expect(@payment).to receive(:capture!).and_return(true) }
    it { expect(@shipment).to receive(:finalize_pos).and_return(true) }
    it { expect(@order).to receive(:deliver_order_confirmation_email).and_return(true) }
    it { expect(@order).to receive(:save!).and_return(true) }

    after { @order.complete_via_pos }
  end

  describe '#assign_shipment_for_pos' do
    context '#is_pos?' do
      before do
        @order = Spree::Order.create!(is_pos: true)
        shipping_category = Spree::ShippingCategory.create! name: 'test-category'
        @shipping_method = Spree::ShippingMethod.new(name: 'test-method') { |method| method.calculator = flat_rate_calculator }
        @shipping_method.shipping_categories << shipping_category
        @shipping_method.save!
        SpreePos::Config[:pos_shipping] = @shipping_method.name
      end

      describe 'method calls' do
        it { expect(@order).to receive(:is_pos?).and_return(true) }

        after { @order.assign_shipment_for_pos }
      end

      it 'create a shipment for order' do
        expect(@order.shipments).to be_blank
        @order.shipments.create_shipment_for_pos_order
        expect(@order.shipments.count).to eq(1)
      end
    end

    context '#is_pos? false' do
      before { allow(@order).to receive(:is_pos?).and_return(false) }

      describe 'method calls' do
        it { expect(@order).to receive(:is_pos?).and_return(false) }
        it { expect(@order.shipments).not_to receive(:create_shipment_for_pos_order) }

        after { @order.assign_shipment_for_pos }
      end
    end
  end

  describe '#save_payment_for_pos' do
    before do
      allow(@payments).to receive(:delete_all).and_return(true)
      allow(@payments).to receive(:create).with(amount: 100, payment_method_id: 1, card_name: 'MasterCard').and_return(@payment)
    end
    it { expect(@payments).to receive(:delete_all).and_return(true) }
    it { expect(@payments).to receive(:create).with(amount: 100, payment_method_id: 1, card_name: 'MasterCard').and_return(@payment) }
    after { @order.save_payment_for_pos(1, 'MasterCard') }
  end

  describe '#associate_user_for_pos' do
    context 'user with email exists' do
      before do
        allow(Spree::User).to receive(:find_by).with(email: user.email).and_return(user)
      end

      context 'when user is valid' do
        before { allow(user).to receive(:valid?).and_return(true) }

        it { expect(Spree::User).to receive(:find_by).with(email: user.email).and_return(user) }
        it { expect(Spree::User).not_to receive(:create_with_random_password) }
        it { expect(@order).to receive(:email=).with(user.email).and_return(true) }
        after { @order.associate_user_for_pos(user.email) }
      end

      context 'when user is not valid' do
        before { allow(user).to receive(:valid?).and_return(false) }

        it { expect(Spree::User).to receive(:find_by).with(email: user.email).and_return(user) }
        it { expect(Spree::User).not_to receive(:create_with_random_password) }
        it { expect(@order).not_to receive(:email=).with(user.email) }
        after { @order.associate_user_for_pos(user.email) }
      end

      it { expect(@order.associate_user_for_pos(user.email)).to eq(user) }
    end

    context 'user with email does not exist' do
      before do
        @new_user = mock_model(Spree::User)
        allow(Spree::User).to receive(:create_with_random_password).with('new-user@pos.com').and_return(@new_user)
      end

      context 'when new user is valid' do
        before { allow(@new_user).to receive(:valid?).and_return(true) }

        it { expect(Spree::User).to receive(:find_by).with(email: 'new-user@pos.com').and_return(nil) } 
        it { expect(Spree::User).to receive(:create_with_random_password).with('new-user@pos.com').and_return(@new_user) }
        it { expect(@order).to receive(:email=).with('new-user@pos.com').and_return(true) }

        after { @order.associate_user_for_pos('new-user@pos.com') }
      end

      context 'when new user is not valid' do
        before { allow(@new_user).to receive(:valid?).and_return(false) }

        it { expect(Spree::User).to receive(:find_by).with(email: 'new-user@pos.com').and_return(nil) } 
        it { expect(Spree::User).to receive(:create_with_random_password).with('new-user@pos.com').and_return(@new_user) }
        it { expect(@order).not_to receive(:email=).with(@new_user.email) }

        after { @order.associate_user_for_pos('new-user@pos.com') }
      end

      it { expect(@order.associate_user_for_pos('new-user@pos.com')).to eq(@new_user) }
    end
  end

  describe '#pos_shipment' do
    before { @shipments = [@shipment] }
    
    it 'should fetch all shipments' do
      expect(@order).to receive(:shipments).and_return(@shipments)
      expect(@shipments).to receive(:last).and_return(@shipment) 
      expect(@order.pos_shipment).to eq(@shipment)
    end
  end
end
