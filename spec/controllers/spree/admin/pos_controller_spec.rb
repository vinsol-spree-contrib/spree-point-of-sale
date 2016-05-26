require 'spec_helper'

describe Spree::Admin::PosController do
  let(:user) { mock_model(Spree::User) }
  let(:order) { mock_model(Spree::Order, number: 'R123456') }
  let(:line_item) { mock_model(Spree::LineItem) }
  let(:product) { mock_model(Spree::Product, name: 'test-product') }
  let(:variant) { mock_model(Spree::Variant, name: 'test-variant', price: 20) }
  let(:payment) { mock_model(Spree::Payment) }
  let(:role) { mock_model(Spree::Role) }
  let(:roles) { [role] }
  let(:address) { mock_model(Spree::Address) }
  let(:line_item_error_object) { ActiveModel::Errors.new(Spree::LineItem) }
  let(:shipment_error_object) { ActiveModel::Errors.new(Spree::Shipment) }

  before do
    allow(controller).to receive(:spree_current_user).and_return(user)
    allow(controller).to receive(:authorize_admin).and_return(true)
    allow(controller).to receive(:authorize!).and_return(true)
    allow(user).to receive(:generate_spree_api_key!).and_return(true)
    allow(user).to receive(:roles).and_return(roles)
    allow(user).to receive(:unpaid_pos_orders).and_return([order])
    allow(roles).to receive(:includes).and_return(roles)
    allow(role).to receive(:ability).and_return(true)
    allow(variant).to receive(:product).and_return(product)
    allow(product).to receive(:save).and_return(true)
    allow(order).to receive(:is_pos?).and_return(true)
    allow(order).to receive(:paid?).and_return(false)
    allow(order).to receive(:reload).and_return(order)
  end

  context 'before filters' do
    before do
      allow(controller).to receive(:ensure_pos_shipping_method).and_return(true)
      allow(controller).to receive(:ensure_active_store).and_return(true)
      @orders = [order]
      allow(Spree::Order).to receive(:where).with(number: order.number).and_return(@orders)
      allow(@orders).to receive(:includes).with([{ line_items: [{ variant: [:default_price, { product: [:master] } ] }] } , { adjustments: :adjustable }]).and_return(@orders)
    end

    describe 'ensure order is pos and unpaid' do
      def send_request(params = {})
        spree_get :show, params
      end

      context 'order does not exist' do
        before do
          @orders = []
          allow(Spree::Order).to receive(:where).with(number: order.number).and_return(@orders)
          allow(@orders).to receive(:includes).with([{ line_items: [{ variant: [:default_price, { product: [:master] } ] }] } , { adjustments: :adjustable }]).and_return(@orders)    
          send_request(number: order.number)
        end

        it { expect(flash[:error]).to eq("No order found for -#{order.number}-")  }
      end

      context 'paid' do
        before do
          allow(order).to receive(:paid?).and_return(true)
        end

        describe 'loads and checks order' do
          it { expect(order).to receive(:paid?).and_return(true) }
          it { expect(controller).not_to receive(:show) }

          after { send_request({ number: order.number }) }
        end

        describe 'response' do
          before { send_request({ number: order.number }) }

          it { expect(flash[:error]).to eq('This order is already completed. Please use a new one.') }
          it { expect(response).to render_template('show') }
        end
      end

      context 'not paid but not pos' do
        before { allow(order).to receive(:is_pos?).and_return(false) }

        describe 'loads and checks order' do
          it { expect(order).to receive(:is_pos?).and_return(false) }
          it { expect(controller).not_to receive(:show) }

          after { send_request({ number: order.number }) }
        end

        describe 'response' do
          before { send_request({ number: order.number }) }

          it { expect(flash[:error]).to eq('This is not a pos order') }
          it { expect(response).to render_template('show') }
        end
      end

      context 'not paid and pos order' do
        before { allow(order).to receive(:paid?).and_return(false) }

        describe 'loads and checks order' do
          it { expect(order).to receive(:paid?).and_return(false) }

          after { send_request({ number: order.number, line_item_id: 1 }) }
        end

        describe 'response' do
          before { send_request({ number: order.number }) }

          it { expect(flash[:error]).to be_nil }
          it { expect(response).to render_template('show') }
        end
      end
    end

    describe 'ensure_active_store' do
      before { allow(controller).to receive(:ensure_active_store).and_call_original }
      def send_request(params = {})
        spree_get :new, params
      end

      context 'store does not exist' do
        it 'redirects to root' do
          send_request
          expect(response).to redirect_to('/')
        end

        it 'sets the flash message' do
          send_request
          expect(flash[:error]).to eq('No active store present. Please assign one.')
        end
      end

      context 'store does exist' do
        before do
          @shipping_method = mock_model(Spree::ShippingMethod, name: 'pos-shipping')
          SpreePos::Config[:pos_shipping] = @shipping_method.name
          @stock_location = mock_model(Spree::StockLocation)
          allow(@stock_location).to receive(:address).and_return(address)
          @stock_locations = [@stock_location]
          allow(@stock_locations).to receive(:where).with(id: @stock_location.id.to_s).and_return(@stock_locations)
          allow(Spree::StockLocation).to receive_message_chain(:active, :stores).and_return(@stock_locations)
          allow(Spree::ShippingMethod).to receive(:where).with(name: @shipping_method.name).and_return([@shipping_method])
        end

        it 'does not redirect to root' do
          send_request
          expect(response).not_to redirect_to('/')
        end

        it 'sets no error message for store' do
          send_request
          expect(flash[:error]).to eq("You have an unpaid/empty order. Please either complete it or update items in the same order.")
        end

        it 'renders show page' do
          send_request
          expect(response).to redirect_to admin_pos_show_order_path(number: order.number)
        end
      end
    end

    describe 'ensure_pos_shipping_method' do
      before do
        allow(controller).to receive(:ensure_pos_shipping_method).and_call_original
        @shipping_method = mock_model(Spree::ShippingMethod, name: 'pos-shipping')
        SpreePos::Config[:pos_shipping] = @shipping_method.name
        @stock_location = mock_model(Spree::StockLocation)
        allow(@stock_location).to receive(:address).and_return(address)
        @stock_locations = [@stock_location]
        allow(@stock_locations).to receive(:where).with(id: @stock_location.id.to_s).and_return(@stock_locations)
        allow(Spree::StockLocation).to receive_message_chain(:active, :stores).and_return(@stock_locations)
      end

      def send_request(params = {})
        spree_get :new, params
      end

      context 'pos_shipping_method exists' do
        before do
          allow(Spree::ShippingMethod).to receive(:find_by).with(name: @shipping_method.name).and_return(@shipping_method)
        end

        it 'checks for the configured shipping method' do
          expect(Spree::ShippingMethod).to receive(:find_by).with(name: @shipping_method.name).and_return(@shipping_method)
          send_request
        end

        context 'response' do
          before { send_request }

          it { expect(flash[:error]).to eq("You have an unpaid/empty order. Please either complete it or update items in the same order.") }
          it { expect(response).not_to redirect_to('/') }
        end
      end

      context 'pos_shipping_method does not exist' do
        before do
          allow(Spree::ShippingMethod).to receive(:find_by).with(name: @shipping_method.name).and_return(nil)
        end

        it 'checks for the configured shipping method' do
          expect(Spree::ShippingMethod).to receive(:find_by).with(name: @shipping_method.name).and_return(nil)
          send_request
        end

        context 'response' do
          before { send_request }

          it { expect(flash[:error]).to eq("No shipping method available for POS orders. Please assign one.") }
          it { expect(response).to redirect_to('/') }
        end
      end
    end

    describe 'load_variant' do
      before do
        allow(controller).to receive(:add_variant).with(variant).and_return(line_item)
      end

      def send_request(params = {})
        spree_post :add, params
      end

      context 'variant present' do
        before do
          allow(Spree::Variant).to receive(:find_by).with(id: variant.id.to_s).and_return(variant)
        end

        it 'checks for the variant' do
          expect(Spree::Variant).to receive(:find_by).with(id: variant.id.to_s).and_return(variant)
          send_request(item: variant.id, number: order.number)
        end

        it 'proceeds further to add' do
          expect(controller).to receive(:add_variant).with(variant).and_return(line_item)
          send_request(item: variant.id, number: order.number)
        end

        it 'sets no flash error' do
          send_request(item: variant.id, number: order.number)
          expect(flash[:error]).to be_nil
        end
      end

      context 'no variant with the id passed' do
        before { allow(Spree::Variant).to receive(:find_by).with(id: variant.id.to_s).and_return(nil) }

        it 'checks for the variant' do
          expect(Spree::Variant).to receive(:find_by).with(id: variant.id.to_s).and_return(nil)
          send_request(item: variant.id, number: order.number)
        end

        it 'renders show' do
          send_request(item: variant.id, number: order.number)
          expect(response).to render_template :show
        end

        it 'sets flash error' do
          send_request(item: variant.id, number: order.number)
          expect(flash[:error]).to eq('No variant')
        end
      end
    end

    describe 'ensure_payment_method' do
      before do
        @payment_method = mock_model(Spree::PaymentMethod)
        allow(controller).to receive(:update_line_item_quantity).and_return(true)      
      end

      def send_request(params = {})
        spree_post :update_payment, params
      end

      context 'payment method exists' do
        before do
          allow(Spree::PaymentMethod).to receive(:where).with(id: @payment_method.id.to_s).and_return([@payment_method])
          allow(order).to receive(:save_payment_for_pos).with(@payment_method.id.to_s, 'Credit Card').and_return(payment)
          allow(order).to receive(:complete_via_pos).and_return(true)
        end

        describe 'response' do
          before { send_request(number: order.number, payment_method_id: @payment_method.id, card_name: 'Credit Card') }

          it { expect(flash[:error]).to be_nil }
        end

        it 'completes the order' do
          expect(order).to receive(:save_payment_for_pos).with(@payment_method.id.to_s, 'Credit Card').and_return(payment)
          expect(order).to receive(:complete_via_pos).and_return(true)
          send_request(number: order.number, payment_method_id: @payment_method.id, card_name: 'Credit Card')
        end
      end

      context 'payment method does not exist' do
        before { allow(Spree::PaymentMethod).to receive(:where).with(id: @payment_method.id.to_s).and_return([]) }

        describe 'response' do
          before { send_request(number: order.number, payment_method_id: @payment_method.id, card_name: 'Credit Card') }

          it { expect(flash[:error]).to eq('Please select a payment method') }
        end

        it 'does not complete the order' do
          expect(order).not_to receive(:save_payment_for_pos)
          expect(order).not_to receive(:complete_via_pos)
          send_request(number: order.number, payment_method_id: @payment_method.id, card_name: 'Credit Card')
        end

        it 'redirects' do
          send_request(number: order.number, payment_method_id: @payment_method.id, card_name: 'Credit Card')
          expect(response).to redirect_to(admin_pos_show_order_path(number: order.number))
        end          
      end
    end

    describe 'ensure existing user' do
      def send_request(params = {})
        spree_post :associate_user, params
      end

      context 'to be associated old user does not exist' do
        before do
          send_request(number: order.number, email: 'non-exist@website.com')
        end

      it { expect(response).to redirect_to(admin_pos_show_order_path(number: order.number)) }
        it { expect(flash[:error]).to eq("No user with email non-exist@website.com") }
      end

      context 'to be added a new user already exists' do
        before do
          @existing_user = Spree::User.create!(email: 'existing@website.com', password: 'iexist')
          send_request(number: order.number, new_email: @existing_user.email)
        end

        it { expect(response).to redirect_to(admin_pos_show_order_path(number: order.number)) }
        it { expect(flash[:error]).to eq("User Already exists for the email #{@existing_user.email}") }
      end
    end
  end

  context 'actions' do
    before do
      allow(controller).to receive(:ensure_pos_shipping_method).and_return(true)
      allow(controller).to receive(:ensure_active_store).and_return(true)
      allow(Spree::StockLocation).to receive_message_chain(:active,:stores,:first,:address).and_return(address)
      controller.instance_variable_set(:@order,order)
    end

    describe 'new' do
      before do
        @current_time = Time.current
        allow(Time).to receive(:current).and_return(@current_time)
        @new_order = Spree::Order.create is_pos: true
        allow(Spree::Order).to receive(:new).and_return(@new_order)
        allow(@new_order).to receive(:assign_shipment_for_pos).and_return(true)
        allow(@new_order).to receive(:associate_user!).and_return(true)
        allow(@new_order).to receive(:save!).and_return(true)
        @stock_location = mock_model(Spree::StockLocation)
        allow(@stock_location).to receive(:address).and_return(address)
        @stock_locations = [@stock_location]
        allow(@stock_locations).to receive(:where).with(id: @stock_location.id.to_s).and_return(@stock_locations)
        allow(Spree::StockLocation).to receive_message_chain(:active, :stores).and_return(@stock_locations)
      end

      def send_request(params = {})
        spree_get :new, params
      end

      context 'before filters' do
        it { expect(controller).to receive(:ensure_active_store).and_return(true) }
        it { expect(controller).to receive(:ensure_pos_shipping_method).and_return(true) }
        it { expect(controller).not_to receive(:ensure_payment_method) }
        after { send_request }
      end

      it 'checks for pending orders' do
        expect(user).to receive(:unpaid_pos_orders).and_return([order])
        send_request
      end

      context 'pending pos order present' do
        it 'adds error' do
          expect(controller).to receive(:add_error).with("You have an unpaid/empty order. Please either complete it or update items in the same order.").and_return(true)
          send_request
        end

        it 'does not initalize with a new order' do
          expect(controller).not_to receive(:init_pos)
          send_request
        end

        it 'redirects to action show' do
          send_request
          expect(response).to redirect_to(admin_pos_show_order_path(number: order.number))
        end
      end

      context 'no pending order' do
        before { allow(user).to receive(:unpaid_pos_orders).and_return([]) }

        context 'init_pos' do
          it { expect(Spree::Order).to receive(:new).with(state: "complete", is_pos: true, completed_at: @current_time, payment_state: 'balance_due').and_return(@new_order) }
          it { expect(@new_order).to receive(:assign_shipment_for_pos).and_return(true) }
          it { expect(@new_order).to receive(:associate_user!).and_return(true) }
          it { expect(@new_order).to receive(:save!).twice.and_return(true) }
          after { send_request }
        end

        it 'redirects to action show' do
          send_request
          expect(response).to redirect_to(admin_pos_show_order_path(number: @new_order.number))
        end
      end
    end

    describe 'update_line_item_quantity' do
      before do
        @orders = [order]
        allow(Spree::Order).to receive(:where).with(number: order.number).and_return(@orders)
        allow(@orders).to receive(:includes).with([{ line_items: [{ variant: [:default_price, { product: [:master] } ] }] } , { adjustments: :adjustable }]).and_return(@orders)
        @line_items = [line_item]
        allow(order).to receive(:line_items).and_return(@line_items)
        allow(@line_items).to receive(:find_by).and_return(line_item)
        allow(line_item).to receive(:save).and_return(true)
        allow(line_item).to receive(:variant).and_return(variant)
        allow(line_item).to receive(:quantity=).with('2').and_return(true)
      end

      def send_request(params = {})
        spree_post :update_line_item_quantity, params
      end

      context 'update_line_item_quantity' do
        it { expect(controller).to receive(:ensure_pos_order).and_return(true) }
        it { expect(controller).to receive(:ensure_unpaid_order).and_return(true) }
        it { expect(controller).to receive(:ensure_active_store).and_return(true) }
        it { expect(controller).to receive(:ensure_pos_shipping_method).and_return(true) }
        it { expect(controller).not_to receive(:ensure_payment_method) }
        it { expect(order).to receive(:line_items).and_return(@line_items) }
        it { expect(line_item).to receive(:quantity=).with('2').and_return(true) }
        it { expect(line_item).to receive(:save).and_return(true) }
        after { send_request(number: order.number, line_item_id: line_item.id, quantity: 2) }
      end

      context 'updated successfully' do
        it 'sets flash message' do
          send_request(number: order.number, line_item_id: line_item.id, quantity: 2)
          expect(flash[:notice]).to eq('Quantity Updated')
        end
      end

      context 'not updated successfully' do
        before do
          line_item_error_object.messages.merge!({base: ["Adding more than available"]})
          allow(line_item).to receive(:errors).and_return(line_item_error_object) 
        end

        it 'sets flash message' do
          send_request(number: order.number, line_item_id: line_item.id, quantity: 2)
          expect(flash[:error]).to eq('Adding more than available')
        end
      end
    end

    describe 'apply discount' do
      def send_request(params = {})
        spree_post :apply_discount, params
      end

      before do
        @orders = [order]
        allow(Spree::Order).to receive(:where).with(number: order.number).and_return(@orders)
        allow(@orders).to receive(:includes).with([{ line_items: [{ variant: [:default_price, { product: [:master] } ] }] } , { adjustments: :adjustable }]).and_return(@orders)
        @line_items = [line_item]
        allow(order).to receive(:line_items).and_return(@line_items)
        allow(@line_items).to receive(:find_by).and_return(line_item)
        allow(line_item).to receive(:save).and_return(true)
        allow(line_item).to receive(:variant).and_return(variant)
        allow(line_item).to receive(:price=).with(18.0).and_return(true)
      end

      it { expect(controller).to receive(:ensure_unpaid_order).and_return(true) }
      it { expect(controller).to receive(:ensure_pos_order).and_return(true) }
      it { expect(controller).to receive(:ensure_pos_shipping_method).and_return(true) }
      it { expect(controller).to receive(:ensure_active_store).and_return(true) }
      it { expect(controller).not_to receive(:ensure_payment_method) }

      it { expect(order).to receive(:line_items).and_return(@line_items) }
      it { expect(line_item).to receive(:variant).and_return(variant) }
      it { expect(line_item).to receive(:save).and_return(true) }
      it { expect(line_item).to receive(:price=).with(18.0).and_return(true) }
      after { send_request(number: order.number, discount: 10, item: line_item.id) }
    end

    describe 'find' do
      def send_request(params = {})
        spree_get :find, params
      end

      before do
        @orders = [order]
        allow(Spree::Order).to receive(:where).with(number: order.number).and_return(@orders)
        allow(@orders).to receive(:includes).with([{ line_items: [{ variant: [:default_price, { product: [:master] } ] }] } , { adjustments: :adjustable }]).and_return(@orders)
        @stock_location = mock_model(Spree::StockLocation)
        @shipment = mock_model(Spree::Shipment)
        allow(order).to receive(:pos_shipment).and_return(@shipment)
        allow(@shipment).to receive(:stock_location).and_return(@stock_location)
        @variants = [variant]
        allow(@variants).to receive(:result).with(distinct: true).and_return(@variants)
        allow(@variants).to receive(:page).with('1').and_return(@variants)
        allow(@variants).to receive(:per).and_return(@variants)
        allow(Spree::Variant).to receive(:includes).with([:product]).and_return(Spree::Variant)
        allow(Spree::Variant).to receive(:available_at_stock_location).with(@stock_location.id).and_return(Spree::Variant)
        allow(Spree::Variant).to receive(:ransack).with({product_name_cont: "test-product", meta_sort: "product_name asc", deleted_at_null: "1", product_deleted_at_null: "1", published_at_not_null: "1"}).and_return(@variants)
      end

      it { expect(controller).to receive(:ensure_pos_order).and_return(true) }
      it { expect(controller).to receive(:ensure_unpaid_order).and_return(true) }
      it { expect(controller).to receive(:ensure_pos_shipping_method).and_return(true) }
      it { expect(controller).to receive(:ensure_active_store).and_return(true) }
      it { expect(controller).not_to receive(:ensure_payment_method) }
      it { expect(order).to receive(:pos_shipment).and_return(@shipment) }
      it { expect(@shipment).to receive(:stock_location).and_return(@stock_location) }
      it { expect(Spree::Variant).to receive(:ransack).with({product_name_cont: "test-product", meta_sort: "product_name asc", deleted_at_null: "1", product_deleted_at_null: "1", published_at_not_null: "1"}).and_return(@variants) }    
      it { expect(@variants).to receive(:result).with(distinct: true).and_return(@variants) }
      it { expect(@variants).to receive(:page).with('1').and_return(@variants) }
      it { expect(@variants).to receive(:per).and_return(@variants) }

      after { send_request(number: order.number, q: { product_name_cont: 'test-product    ' }, page: 1) } 
    end

    describe 'print' do
      def send_request(params = {})
        spree_post :update_payment, params
      end

      before do
        @orders = [order]
        allow(Spree::Order).to receive(:where).with(number: order.number).and_return(@orders)
        allow(@orders).to receive(:includes).with([{ line_items: [{ variant: [:default_price, { product: [:master] } ] }] } , { adjustments: :adjustable }]).and_return(@orders)
        @payment_method = mock_model(Spree::PaymentMethod)
        allow(Spree::PaymentMethod).to receive(:where).with(id: @payment_method.id.to_s).and_return([@payment_method])
        allow(order).to receive(:save_payment_for_pos).with(@payment_method.id.to_s, 'Credit Card').and_return(payment)
        allow(order).to receive(:complete_via_pos).and_return(true)
      end
      
      it 'completes order via pos' do
        expect(order).to receive(:complete_via_pos).and_return(true)
        send_request(number: order.number, payment_method_id: @payment_method.id, card_name: 'Credit Card')
      end

      it 'redirects to print url' do
        send_request(number: order.number, payment_method_id: @payment_method.id, card_name: 'Credit Card')
        expect(response).to redirect_to("/admin/invoice/#{order.number}/receipt")
      end
    end

    describe 'add' do
      before do
        @orders = [order]
        allow(Spree::Order).to receive(:where).with(number: order.number).and_return(@orders)
        allow(@orders).to receive(:includes).with([{ line_items: [{ variant: [:default_price, { product: [:master] } ] }] } , { adjustments: :adjustable }]).and_return(@orders)
        allow(Spree::Variant).to receive(:find_by).with(id: variant.id.to_s).and_return(variant)
        @order_contents = double(Spree::OrderContents)
        @shipment = mock_model(Spree::Shipment)
        allow(order).to receive(:pos_shipment).and_return(@shipment)
        allow(order).to receive(:contents).and_return(@order_contents)
        allow(@order_contents).to receive(:add).with(variant, 1, shipment: @shipment).and_return(line_item)
      end

      def send_request(params = {})
        spree_post :add, params
      end

      describe 'adds to order' do
        it { expect(controller).to receive(:ensure_pos_order).and_return(true) }
        it { expect(controller).to receive(:ensure_unpaid_order).and_return(true) }
        it { expect(controller).to receive(:ensure_pos_shipping_method).and_return(true) }
        it { expect(controller).to receive(:ensure_active_store).and_return(true) }
        it { expect(controller).not_to receive(:ensure_payment_method) }

        it { expect(order).to receive(:contents).and_return(@order_contents) }
        it { expect(@order_contents).to receive(:add).with(variant, 1, shipment: @shipment).and_return(line_item) }
        it { expect(product).to receive(:save).and_return(true) }

        after { send_request(number: order.number, item: variant.id) }
      end

      it 'assigns line_item' do
        send_request(number: order.number, item: variant.id)
        expect(assigns(:item)).to eq(line_item)
      end

      context 'added successfully' do
        it 'redirects to action show' do
          send_request(number: order.number, item: variant.id)
          expect(response).to redirect_to(admin_pos_show_order_path(number: order.number))
        end

        it 'sets the flash message' do
          send_request(number: order.number, item: variant.id)
          expect(flash[:notice]).to eq('Product added')
        end
      end

      context 'not added successfully' do
        before do
          line_item_error_object.messages.merge!({base: ["Adding more than available"]})
          allow(line_item).to receive(:errors).and_return(line_item_error_object)
        end

        it 'redirects to action show' do
          send_request(number: order.number, item: variant.id)
          expect(response).to redirect_to(admin_pos_show_order_path(number: order.number))
        end

        it 'sets the flash message' do
          send_request(number: order.number, item: variant.id)
          expect(flash[:error]).to eq('Adding more than available')
        end
      end
    end

    describe 'remove' do
      before do
        @orders = [order]
        allow(Spree::Order).to receive(:where).with(number: order.number).and_return(@orders)
        allow(@orders).to receive(:includes).with([{ line_items: [{ variant: [:default_price, { product: [:master] } ] }] } , { adjustments: :adjustable }]).and_return(@orders)
        allow(Spree::Variant).to receive(:find_by).with(id: variant.id.to_s).and_return(variant)
        @order_contents = double(Spree::OrderContents)
        @shipment = mock_model(Spree::Shipment)
        allow(order).to receive(:pos_shipment).and_return(@shipment)
        allow(order).to receive(:assign_shipment_for_pos).and_return(true)
        allow(order).to receive(:contents).and_return(@order_contents)
        allow(@order_contents).to receive(:remove).with(variant, 1, @shipment).and_return(line_item)
        allow(line_item).to receive(:quantity).and_return(1)
      end

      def send_request(params = {})
        spree_post :remove, params
      end

      describe 'removes from order' do
        it { expect(controller).to receive(:ensure_pos_order).and_return(true) }
        it { expect(controller).to receive(:ensure_unpaid_order).and_return(true) }
        it { expect(controller).to receive(:ensure_pos_shipping_method).and_return(true) }
        it { expect(controller).to receive(:ensure_active_store).and_return(true) }
        it { expect(controller).not_to receive(:ensure_payment_method) }
        
        it { expect(order).to receive(:contents).and_return(@order_contents) }
        it { expect(@order_contents).to receive(:remove).with(variant, 1, @shipment).and_return(line_item) }
        
        after { send_request(number: order.number, item: variant.id) }
      end

      context 'item quantity is now 0' do
        before { allow(line_item).to receive(:quantity).and_return(0) }
        it 'sets flash message' do
          send_request(number: order.number, item: variant.id)
          expect(flash[:notice]).to eq(Spree.t('product_removed'))
        end
      end

      context 'item quantity is now not 0' do
        it 'sets flash message' do
          send_request(number: order.number, item: variant.id)
          expect(flash[:notice]).to eq('Quantity Updated')
        end
      end

      context 'shipment is not destroyed on empty order' do
        it 'assigns shipment' do
          expect(order).not_to receive(:assign_shipment_for_pos)
          send_request(number: order.number, item: variant.id)
        end
      end

      context 'shipment destroyed after remove' do
        before { allow(order).to receive_message_chain(:pos_shipment, :blank?).and_return(true) }

        it 'assigns shipment' do
          expect(order).to receive(:assign_shipment_for_pos).and_return(true)
          send_request(number: order.number, item: variant.id)
        end
      end

      it 'redirects to action show' do
        send_request(number: order.number, item: variant.id)
        expect(response).to redirect_to(admin_pos_show_order_path(number: order.number))
      end
    end

    describe 'clean_order' do
      before do
        @orders = [order]
        allow(Spree::Order).to receive(:where).with(number: order.number).and_return(@orders)
        allow(@orders).to receive(:includes).with([{ line_items: [{ variant: [:default_price, { product: [:master] } ] }] } , { adjustments: :adjustable }]).and_return(@orders)
        allow(order).to receive(:clean!).and_return(true)
      end

      def send_request(params = {})
        spree_put :clean_order, params
      end

      context 'before filters' do
        it { expect(controller).to receive(:ensure_unpaid_order).and_return(true) }
        it { expect(controller).to receive(:ensure_pos_order).and_return(true) }
        it { expect(controller).to receive(:ensure_pos_shipping_method).and_return(true) }
        it { expect(controller).to receive(:ensure_active_store).and_return(true) }
        it { expect(controller).not_to receive(:ensure_payment_method) }
        after { send_request({number: order.number}) }
      end

      it 'calls clean! method on order' do
        expect(order).to receive(:clean!).and_return(true)
        send_request({number: order.number})
      end

      it 'redirects to action show' do
        send_request(number: order.number)
        expect(response).to redirect_to(admin_pos_show_order_path(number: order.number))
      end

      it 'sets flash message' do
        send_request({number: order.number})
        expect(flash[:notice]).to eq('Removed all items')
      end
    end

    describe 'associate_user' do
      before do
        @orders = [order]
        allow(Spree::Order).to receive(:where).with(number: order.number).and_return(@orders)
        allow(@orders).to receive(:includes).with([{ line_items: [{ variant: [:default_price, { product: [:master] } ] }] } , { adjustments: :adjustable }]).and_return(@orders)
        allow(order).to receive(:associate_user_for_pos).with('test-user@pos.com').and_return(user)
        allow(order).to receive(:save!).and_return(true)
      end

      def send_request(params = {})
        spree_post :associate_user, params
      end

      context 'before filters' do
        it { expect(controller).to receive(:ensure_unpaid_order).and_return(true) }
        it { expect(controller).to receive(:ensure_pos_order).and_return(true) }
        it { expect(controller).to receive(:ensure_pos_shipping_method).and_return(true) }
        it { expect(controller).to receive(:ensure_active_store).and_return(true) }
        it { expect(controller).not_to receive(:ensure_payment_method) }
        after { send_request(number: order.number, new_email:'test-user@pos.com') }
      end

      it 'associates user with order' do
        expect(order).to receive(:associate_user_for_pos).with('test-user@pos.com').and_return(user)
        send_request(number: order.number, new_email:'test-user@pos.com')
      end

      it 'saves the changes in order' do
        expect(order).to receive(:save!).and_return(true)
        send_request(number: order.number, new_email:'test-user@pos.com')
      end

      context 'if user added successfully' do
        it 'redirects to action show' do
          send_request(number: order.number, new_email:'test-user@pos.com')
          expect(response).to redirect_to(admin_pos_show_order_path(number: order.number))
        end

        it 'sets the flash message' do
          send_request(number: order.number, new_email:'test-user@pos.com')
          expect(flash[:notice]).to eq('Successfully Associated User')
        end
      end

      context 'if user not added' do
        before do
          @error_object = Object.new
          allow(@error_object).to receive_message_chain(:full_messages, :to_sentence).and_return('error_message')
          allow(user).to receive(:errors).and_return(@error_object)
        end

        it 'redirects to action show' do
          send_request(number: order.number, new_email:'test-user@pos.com')
          expect(response).to redirect_to(admin_pos_show_order_path(number: order.number))
        end

        it 'sets the flash message' do
          send_request(number: order.number, new_email:'test-user@pos.com')
          expect(flash[:error]).to eq('Could not add the user: error_message')
        end
      end
    end

    describe 'update_payment' do
      def send_request(params = {})
        spree_post :update_payment, params
      end

      before do
        @orders = [order]
        allow(Spree::Order).to receive(:where).with(number: order.number).and_return(@orders)
        allow(@orders).to receive(:includes).with([{ line_items: [{ variant: [:default_price, { product: [:master] } ] }] } , { adjustments: :adjustable }]).and_return(@orders)
        @payment_method = mock_model(Spree::PaymentMethod)
        allow(Spree::PaymentMethod).to receive(:where).with(id: @payment_method.id.to_s).and_return([@payment_method])
        allow(order).to receive(:save_payment_for_pos).with(@payment_method.id.to_s, 'Credit Card').and_return(payment)
        allow(order).to receive(:complete_via_pos).and_return(true)
      end

      context 'before filters' do
        it { expect(controller).to receive(:ensure_active_store).and_return(true) }
        it { expect(controller).to receive(:ensure_pos_shipping_method).and_return(true) }
        it { expect(controller).to receive(:ensure_payment_method).and_return(true) }
        it { expect(controller).to receive(:ensure_pos_order).and_return(true) }
        it { expect(controller).to receive(:ensure_unpaid_order).and_return(true) }

        after { send_request(number: order.number, payment_method_id: @payment_method.id, card_name: 'Credit Card') }
      end

      it 'save payment for order' do
        expect(order).to receive(:save_payment_for_pos).with(@payment_method.id.to_s, 'Credit Card').and_return(payment)
        send_request(number: order.number, payment_method_id: @payment_method.id, card_name: 'Credit Card')
      end

      context 'payment successfully updated' do
        it 'prints the order' do
          expect(controller).to receive(:print){ controller.render nothing: true }
          send_request(number: order.number, payment_method_id: @payment_method.id, card_name: 'Credit Card')
        end
      end

      context 'payment not saved' do
        before do
          @error_object = Object.new
          allow(@error_object).to receive_message_chain(:full_messages, :to_sentence).and_return('error_message')
          allow(payment).to receive(:errors).and_return(@error_object)
        end

        it 'redirects to action show' do
          send_request(number: order.number, payment_method_id: @payment_method.id, card_name: 'Credit Card')
          expect(response).to redirect_to(admin_pos_show_order_path(number: order.number))
        end

        it 'sets the error message' do
          send_request(number: order.number, payment_method_id: @payment_method.id, card_name: 'Credit Card')
          expect(flash[:error]).to eq('error_message')
        end

        it 'should not complete order' do
          expect(order).not_to receive(:complete_via_pos)
          send_request(number: order.number, payment_method_id: @payment_method.id, card_name: 'Credit Card')
        end
      end
    end

    describe 'update_stock_location' do
      def send_request(params = {})
        spree_put :update_stock_location, params
      end

      before do
        @orders = [order]
        allow(order).to receive(:clean!).and_return(true)
        allow(order).to receive(:assign_shipment_for_pos).and_return(true)
        allow(Spree::Order).to receive(:where).with(number: order.number).and_return(@orders)
        allow(@orders).to receive(:includes).with([{ line_items: [{ variant: [:default_price, { product: [:master] } ] }] } , { adjustments: :adjustable }]).and_return(@orders)
        @stock_location = mock_model(Spree::StockLocation)
        allow(@stock_location).to receive(:address).and_return(address)
        @stock_locations = [@stock_location]
        allow(@stock_locations).to receive(:find_by).with(id: @stock_location.id.to_s).and_return(@stock_locations)
        allow(Spree::StockLocation).to receive_message_chain(:active, :stores).and_return(@stock_locations)

        @shipment = mock_model(Spree::Shipment)
        allow(order).to receive(:ship_address=).with(address).and_return(address)
        allow(order).to receive(:bill_address=).with(address).and_return(address)
        allow(@shipment).to receive(:stock_location=).and_return(@stock_location)
        allow(@shipment).to receive(:stock_location).and_return(@stock_location)
        allow(order).to receive(:pos_shipment).and_return(@shipment)

        allow(order).to receive(:save).and_return(true)
        allow(@shipment).to receive(:save).and_return(true)
      end

      describe 'updates order addresses and update shipment' do
        it { expect(order).to receive(:clean!).and_return(true) }
        it { expect(controller).to receive(:load_order).twice.and_return(true) }
        it { expect(@shipment).to receive(:stock_location=).and_return(@stock_location) }
        it { expect(order).to receive(:pos_shipment).and_return(@shipment) }
        it { expect(@shipment).to receive(:save).and_return(true) }
        it { expect(controller).to receive(:ensure_pos_shipping_method).and_return(true) }
        it { expect(controller).to receive(:ensure_active_store).and_return(true) }
        it { expect(controller).not_to receive(:ensure_payment_method) }
        it { expect(controller).to receive(:ensure_unpaid_order).and_return(true) }
        it { expect(controller).to receive(:ensure_pos_order).and_return(true) }

        after { send_request(number: order.number, stock_location_id: @stock_location.id) }
      end

      context 'shipment saved successfully' do
        it 'sets notice' do
          send_request(number: order.number, stock_location_id: @stock_location.id)
          expect(flash[:notice]).to eq('Updated Successfully')
        end
      end

      context 'shipment not saved successfully' do
        before do
          shipment_error_object.messages.merge!({base: ["Error Message"]})
          allow(@shipment).to receive(:errors).and_return(shipment_error_object)
          allow(@shipment).to receive(:save).and_return(false)
        end

        it 'sets error' do
          send_request(number: order.number, stock_location_id: @stock_location.id)
          expect(flash[:error]).to eq('Error Message')
        end
      end

      it 'redirects to action show' do
        send_request(number: order.number, stock_location_id: @stock_location.id)
        expect(response).to redirect_to(admin_pos_show_order_path(number: order.number))
      end
    end
  end
end
