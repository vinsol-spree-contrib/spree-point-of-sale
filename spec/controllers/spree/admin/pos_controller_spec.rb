require 'spec_helper'

describe Spree::Admin::PosController do
  let(:user) { mock_model(Spree::User) }
  let(:order) { mock_model(Spree::Order, :number => 'R123456') }
  let(:line_item) { mock_model(Spree::LineItem) }  
  let(:product) { mock_model(Spree::Product, :name => 'test-product') }
  let(:variant) { mock_model(Spree::Variant, :name => 'test-variant', :price => 20) }
  let(:payment) { mock_model(Spree::Payment) }
  let(:role) { mock_model(Spree::Role) }
  let(:roles) { [role] }
  let(:address) { mock_model(Spree::Address) }

  before do
    controller.stub(:spree_current_user).and_return(user)
    controller.stub(:authorize_admin).and_return(true)
    controller.stub(:authorize!).and_return(true)
    user.stub(:generate_spree_api_key!).and_return(true)
    user.stub(:roles).and_return(roles)
    user.stub(:pending_pos_orders).and_return([order])
    roles.stub(:includes).and_return(roles)
    role.stub(:ability).and_return(true)
    variant.stub(:product).and_return(product)
    product.stub(:save).and_return(true)
    order.stub(:reload).and_return(true)      
    order.stub(:is_pos?).and_return(true)
    order.stub(:paid?).and_return(false)
  end

  context 'before filters' do
    before do
      Spree::Order.stub(:where).with(:number => order.number).and_return([order])
    end
    
    describe 'check_valid_order' do
      def send_request(params = {})
        get :show, params.merge({:use_route => 'spree'})
      end

      context 'order does not exist' do
        before { Spree::Order.stub(:where).with(:number => order.number).and_return([]) }

        it { expect { send_request(:number => order.number) }.to raise_error "No order found for -#{order.number}-"  }
      end

      context 'paid' do
        before { order.stub(:paid?).and_return(true) }

        describe 'loads and checks order' do
          it { Spree::Order.should_receive(:where).with(:number => order.number).and_return([order]) }
          it { order.should_receive(:paid?).and_return(true) }
          it { controller.should_not_receive(:show) }

          after { send_request({ :number => order.number }) }
        end

        describe 'response' do
          before { send_request({ :number => order.number }) }

          it { flash[:error].should eq('This order is already completed. Please use a new one.') }
          it { response.should render_template('show') }
        end
      end

      context 'not paid but not pos' do
        before { order.stub(:is_pos?).and_return(false) }

        describe 'loads and checks order' do
          it { Spree::Order.should_receive(:where).with(:number => order.number).and_return([order]) }
          it { order.should_receive(:paid?).and_return(true) }
          it { order.should_receive(:is_pos?).and_return(false) }
          it { controller.should_not_receive(:show) }

          after { send_request({ :number => order.number }) }
        end

        describe 'response' do
          before { send_request({ :number => order.number }) }

          it { flash[:error].should eq('This is not a pos order') }
          it { response.should render_template('show') }
        end
      end

      context 'not paid and pos order' do
        before { order.stub(:paid?).and_return(false) }

        describe 'loads and checks order' do
          it { Spree::Order.should_receive(:where).with(:number => order.number).and_return([order]) }
          it { order.should_receive(:paid?).and_return(false) }
          it { controller.request.should_receive(:post?).and_return(false) }

          after { send_request({ :number => order.number, :line_item_id => 1 }) }
        end

        describe 'response' do
          before { send_request({ :number => order.number }) }

          it { flash[:error].should be_nil }
          it { response.should render_template('show') }
        end
      end
    end

    describe 'ensure_pos_shipping_method' do
      before do
        @shipping_method = mock_model(Spree::ShippingMethod, :name => 'pos-shipping')
        SpreePos::Config[:pos_shipping] = @shipping_method.name
      end

      def send_request(params = {})
        get :new, params.merge!(:use_route => 'spree')
      end

      context 'pos_shipping_method exists' do
        before do
          Spree::ShippingMethod.stub(:where).with(:name => @shipping_method.name).and_return([@shipping_method])
        end

        it 'checks for the configured shipping method' do
          Spree::ShippingMethod.should_receive(:where).with(:name => @shipping_method.name).and_return([@shipping_method])
          send_request
        end

        context 'response' do
          before { send_request }

          it { flash[:error].should eq("You have an upaid/empty order. Please either complete it or update items in the same order.") }
          it { response.should_not redirect_to('/') }
        end
      end

      context 'pos_shipping_method does not exist' do
        before do
          Spree::ShippingMethod.stub(:where).with(:name => @shipping_method.name).and_return([])
        end

        it 'checks for the configured shipping method' do
          Spree::ShippingMethod.should_receive(:where).with(:name => @shipping_method.name).and_return([])
          send_request
        end

        context 'response' do
          before { send_request }

          it { flash[:error].should eq("No shipping method available for POS orders. Please assign one.") }
          it { response.should redirect_to('/') }
        end
      end
    end

    describe 'load_variant' do
      before do
        controller.stub(:add_variant).with(variant).and_return(line_item)
      end

      def send_request(params = {})
        post :add, params.merge!(:use_route => 'spree')
      end

      context 'variant present' do
        before do
          Spree::Variant.stub(:where).with(:id => variant.id.to_s).and_return([variant])
        end

        it 'checks for the variant' do
          Spree::Variant.should_receive(:where).with(:id => variant.id.to_s).and_return([variant])
          send_request(:item => variant.id, :number => order.number)
        end

        it 'proceeds further to add' do
          controller.should_receive(:add_variant).with(variant).and_return(line_item)
          send_request(:item => variant.id, :number => order.number)
        end

        it 'sets no flash error' do
          send_request(:item => variant.id, :number => order.number)
          flash[:error].should be_nil
        end
      end

      context 'no variant with the id passed' do
        before { Spree::Variant.stub(:where).with(:id => variant.id.to_s).and_return([]) }
        
        it 'checks for the variant' do
          Spree::Variant.should_receive(:where).with(:id => variant.id.to_s).and_return([])
          send_request(:item => variant.id, :number => order.number)
        end

        it 'renders show' do
          send_request(:item => variant.id, :number => order.number)
          response.should render_template :show
        end

        it 'sets flash error' do
          send_request(:item => variant.id, :number => order.number)
          flash[:error].should eq('No variant')
        end
      end
    end

    describe 'ensure_payment_method' do
      before do
        @payment_method = mock_model(Spree::PaymentMethod)
        controller.stub(:update_line_item_quantity).and_return(true)      
      end

      def send_request(params = {})
        post :update_payment, params.merge!({ :use_route => 'spree'})
      end

      context 'payment method exists' do
        before do
          Spree::PaymentMethod.stub(:where).with(:id => @payment_method.id.to_s).and_return([@payment_method])
          order.stub(:save_payment_for_pos).with(@payment_method.id.to_s, 'Credit Card').and_return(payment)
          order.stub(:complete_via_pos).and_return(true)
        end

        describe 'response' do
          before { send_request(:number => order.number, :payment_method_id => @payment_method.id, :card_name => 'Credit Card') }

          it { flash[:error].should be_nil }
        end

        it 'completes the order' do
          order.should_receive(:save_payment_for_pos).with(@payment_method.id.to_s, 'Credit Card').and_return(payment)
          order.should_receive(:complete_via_pos).and_return(true)
          send_request(:number => order.number, :payment_method_id => @payment_method.id, :card_name => 'Credit Card')
        end
      end

      context 'payment method does not exist' do
        before { Spree::PaymentMethod.stub(:where).with(:id => @payment_method.id.to_s).and_return([]) }

        describe 'response' do
          before { send_request(:number => order.number, :payment_method_id => @payment_method.id, :card_name => 'Credit Card') }

          it { flash[:error].should eq('Please select a payment method') }
        end

        it 'does not complete the order' do
          order.should_not_receive(:save_payment_for_pos)
          order.should_not_receive(:complete_via_pos)
          send_request(:number => order.number, :payment_method_id => @payment_method.id, :card_name => 'Credit Card')
        end

        it 'redirects' do
          send_request(:number => order.number, :payment_method_id => @payment_method.id, :card_name => 'Credit Card')
          response.should redirect_to(:action => :show, :number => order.number)
        end          
      end
    end
  end

  context 'actions' do
    before do
      controller.stub(:ensure_pos_shipping_method).and_return(true)
      controller.stub(:ensure_payment_method).and_return(true)
      Spree::StockLocation.stub_chain(:active,:stores,:first,:address).and_return(address)
    end

    describe 'new' do
      before do
        @current_time = Time.current
        Time.stub(:current).and_return(@current_time)
        @new_order = Spree::Order.create :is_pos => true
        Spree::Order.stub(:new).and_return(@new_order)
        @new_order.stub(:assign_shipment_for_pos).and_return(true)
        @new_order.stub(:associate_user!).and_return(true)
        @new_order.stub(:save!).and_return(true)
      end

      def send_request(params = {})
        get :new, params.merge!(:use_route => 'spree')
      end

      it 'checks for pending orders' do
        user.should_receive(:pending_pos_orders).and_return([order])
        send_request
      end

      context 'pending pos order present' do
        it 'adds error' do
          controller.should_receive(:add_error).with("You have an upaid/empty order. Please either complete it or update items in the same order.").and_return(true)
          send_request
        end

        it 'does not initalize with a new order' do
          controller.should_not_receive(:init_pos)
          send_request
        end

        it 'redirects to action show' do
          send_request
          response.should redirect_to(:action => :show, :number => order.number)
        end
      end

      context 'no pending order' do
        before { user.stub(:pending_pos_orders).and_return([]) }
        
        context 'init_pos' do
          it { Spree::Order.should_receive(:new).with(:state => "complete", :is_pos => true, :completed_at => @current_time, :payment_state => 'balance_due').and_return(@new_order) }
          it { @new_order.should_receive(:assign_shipment_for_pos).and_return(true) }
          it { @new_order.should_receive(:associate_user!).and_return(true) }
          it { @new_order.should_receive(:save!).twice.and_return(true) }
          it { @new_order.should_receive(:bill_address=).with(address).and_return(address) }
          it { @new_order.should_receive(:ship_address=).with(address).and_return(address) }
          after { send_request }
        end

        it 'redirects to action show' do
          send_request
          response.should redirect_to(:action => :show, :number => @new_order.number)
        end
      end
    end

    describe 'show' do
      before do
        Spree::Order.stub(:where).with(:number => order.number).and_return([order])
      end

      def send_request(params = {})
        post :show, params.merge!({:use_route => 'spree'})
      end

      context 'line_item_id passed' do
        context 'post request' do
          before do
            @line_items = [line_item]
            order.stub(:line_items).and_return(@line_items)
            line_item.stub(:quantity=).with(2).and_return(true)
            line_item.stub(:save).and_return(true)
            line_item.stub(:variant).and_return(variant)
          end

          context 'update_line_item_quantity' do
            it { order.should_receive(:line_items).and_return(@line_items) }
            it { line_item.should_receive(:quantity=).with(2).and_return(true) }
            it { line_item.should_receive(:save).and_return(true) }
            it { line_item.should_receive(:variant).and_return(variant) }
            it { variant.should_receive(:product).and_return(product) }
            it { product.should_receive(:save).and_return(true) }
            it { order.should_receive(:reload).and_return(true) }
            after { send_request(:number => order.number, :line_item_id => line_item.id, :quantity => 2) }
          end

          context 'updated successfully' do
            it 'sets flash message' do
              send_request(:number => order.number, :line_item_id => line_item.id, :quantity => 2)
              flash[:notice].should eq('Quantity Updated')
            end
          end

          context 'not updated successfully' do
            before { line_item.stub(:errors).and_return(:base => 'error') }
            it 'sets flash message' do
              send_request(:number => order.number, :line_item_id => line_item.id, :quantity => 2)
              flash[:notice].should eq('Adding more than available.')
            end
          end
          it 'should not update discount' do          
            controller.should_not_receive(:apply_discount)
            send_request(:number => order.number, :line_item_id => line_item.id, :quantity => 2)
          end
          
          it 'checks for pos request' do
            controller.request.should_receive(:post?).and_return(true)
            send_request(:number => order.number, :line_item_id => line_item.id, :quantity => 2)
          end
        end

        context 'not post request' do
          def send_request(params = {})
            get :show, params.merge!({:use_route => 'spree'})
          end
          it { controller.should_not_receive(:update_line_item_quantity) }
          it { controller.should_not_receive(:apply_discount) }
          it { controller.request.should_receive(:post?).and_return(false) }
          after { send_request(:number => order.number, :line_item_id => 1) }
        end
      end

      context 'discount passed' do
        before do
          @line_items = [line_item]
          order.stub(:line_items).and_return(@line_items)
          line_item.stub(:variant).and_return(variant)
          line_item.stub(:save).and_return(true)
          line_item.stub(:price=).with(18.0).and_return(true)
        end

        context 'applies discount' do
          it { order.stub(:line_items).and_return(@line_items) }
          it { line_item.stub(:variant).and_return(variant) }
          it { order.stub(:reload).and_return(true) }
          it { line_item.stub(:save).and_return(true) }
          it { line_item.stub(:price=).with(18.0).and_return(true) }
          after { send_request(:number => order.number, :discount => 10, :item => line_item.id) }
        end

        it 'should not update line items quantity' do
          controller.should_not_receive(:update_line_item_quantity) 
          send_request(:number => order.number, :discount => 10, :item => line_item.id)
        end
      end

      context 'search params passed' do
        it { controller.should_not_receive(:update_line_item_quantity) }
        it { controller.should_not_receive(:apply_discount) }
        after { send_request(:number => order.number, :sku => 1) }
      end
    end

    describe 'find' do
      def send_request(params = {})
        get :find, params.merge!(:use_route => 'spree')
      end

      before do
        Spree::Order.stub(:where).with(:number => order.number).and_return([order])
        @stock_location = mock_model(Spree::StockLocation)
        controller.stub(:user_stock_locations).with(user).and_return([@stock_location])
        @variants = [variant]
        @variants.stub(:result).with(:distinct => true).and_return(@variants)
        @variants.stub(:page).with('1').and_return(@variants)
        @variants.stub(:per).and_return(@variants)
        Spree::Variant.stub(:available_at_stock_location).with(@stock_location.id).and_return(Spree::Variant)
        Spree::Variant.stub(:ransack).with({"product_name_cont"=>"test-product", "meta_sort"=>"product_name asc", "deleted_at_null"=>"1", "product_deleted_at_null"=>"1", "published_at_not_null"=>"1"}).and_return(@variants)
      end
      
      it { Spree::Variant.should_receive(:ransack).with({"product_name_cont"=>"test-product", "meta_sort"=>"product_name asc", "deleted_at_null"=>"1", "product_deleted_at_null"=>"1", "published_at_not_null"=>"1"}).and_return(@variants) }    
      it { @variants.should_receive(:result).with(:distinct => true).and_return(@variants) }
      it { @variants.should_receive(:page).with('1').and_return(@variants) }
      it { @variants.should_receive(:per).and_return(@variants) }
        
      after { send_request(:number => order.number, :q => { :product_name_cont => 'test-product    ' }, :page => 1) } 
    end

    describe 'print' do
      def send_request(params = {})
        post :update_payment, params.merge!({ :use_route => 'spree'})
      end

      before do
        Spree::Order.stub(:where).with(:number => order.number).and_return([order])
        @payment_method = mock_model(Spree::PaymentMethod)
        Spree::PaymentMethod.stub(:where).with(:id => @payment_method.id.to_s).and_return([@payment_method])
        order.stub(:save_payment_for_pos).with(@payment_method.id.to_s, 'Credit Card').and_return(payment)
        order.stub(:complete_via_pos).and_return(true)
      end

      it 'completes order via pos' do
        order.should_receive(:complete_via_pos).and_return(true)
        send_request(:number => order.number, :payment_method_id => @payment_method.id, :card_name => 'Credit Card')
      end

      it 'redirects to print url' do
        send_request(:number => order.number, :payment_method_id => @payment_method.id, :card_name => 'Credit Card')
        response.should redirect_to("/admin/invoice/#{order.number}/receipt")
      end
    end

    describe 'add' do
      before do
        Spree::Order.stub(:where).with(:number => order.number).and_return([order])
        Spree::Variant.stub(:where).with(:id => variant.id.to_s).and_return([variant])
        @order_contents = double(Spree::OrderContents)
        @shipment = mock_model(Spree::Shipment)
        order.stub(:shipment).and_return(@shipment)
        order.stub(:contents).and_return(@order_contents)
        @order_contents.stub(:add).with(variant, 1, nil, @shipment).and_return(line_item)
      end

      def send_request(params = {})
        post :add, params.merge!(:use_route => 'spree')
      end

      describe 'adds to order' do
        it { order.should_receive(:contents).and_return(@order_contents) }
        it { @order_contents.should_receive(:add).with(variant, 1, nil, @shipment).and_return(line_item) }
        it { product.should_receive(:save).and_return(true) }
        
        after { send_request(:number => order.number, :item => variant.id) }
      end

      it 'assigns line_item' do
        send_request(:number => order.number, :item => variant.id)
        assigns(:line_item).should eq(line_item)
      end

      context 'added successfully' do
        it 'redirects to action show' do
          send_request(:number => order.number, :item => variant.id)
          response.should redirect_to(:action => :show, :number => order.number)
        end

        it 'sets the flash message' do
          send_request(:number => order.number, :item => variant.id)
          flash[:notice].should eq('Product added')
        end
      end

      context 'not added successfully' do
        before {line_item.stub(:errors).and_return(:base => "error")}
        
        it 'redirects to action show' do
          send_request(:number => order.number, :item => variant.id)
          response.should redirect_to(:action => :show, :number => order.number)
        end

        it 'sets the flash message' do
          send_request(:number => order.number, :item => variant.id)
          flash[:notice].should eq('Adding more than available')
        end
      end
    end

    describe 'remove' do
      before do
        Spree::Order.stub(:where).with(:number => order.number).and_return([order])
        Spree::Variant.stub(:where).with(:id => variant.id.to_s).and_return([variant])
        @order_contents = double(Spree::OrderContents)
        @shipment = mock_model(Spree::Shipment)
        order.stub(:shipment).and_return(@shipment)
        order.stub(:contents).and_return(@order_contents)
        @order_contents.stub(:remove).with(variant, 1, @shipment).and_return(line_item)
        line_item.stub(:quantity).and_return(1)
      end

      def send_request(params = {})
        post :remove, params.merge!(:use_route => 'spree')
      end

      describe 'removes from order' do
        it { order.should_receive(:contents).and_return(@order_contents) }
        it { @order_contents.should_receive(:remove).with(variant, 1, @shipment).and_return(line_item) }
        
        after { send_request(:number => order.number, :item => variant.id) }
      end

      context 'item quantity is now 0' do
        before { line_item.stub(:quantity).and_return(0) }
        it 'sets flash message' do
          send_request(:number => order.number, :item => variant.id)
          flash[:notice].should eq(Spree.t('product_removed'))
        end
      end

      context 'item quantity is now not 0' do
        it 'sets flash message' do
          send_request(:number => order.number, :item => variant.id)
          flash[:notice].should eq('Quantity Updated')
        end
      end

      it 'redirects to action show' do
        send_request(:number => order.number, :item => variant.id)
        response.should redirect_to(:action => :show, :number => order.number)
      end
    end

    describe 'clean_order' do
      before do
        Spree::Order.stub(:where).with(:number => order.number).and_return([order])
        order.stub(:clean!).and_return(true)
      end

      def send_request(params = {})
        put :clean_order, params.merge!({:use_route => 'spree'})
      end

      it 'calls clean! method on order' do
        order.should_receive(:clean!).and_return(true)
        send_request({:number => order.number})
      end

      it 'redirects to action show' do
        send_request(:number => order.number)
        response.should redirect_to(:action => :show, :number => order.number)
      end

      it 'sets flash message' do
        send_request({:number => order.number})
        flash[:notice].should eq('Removed all items')        
      end
    end

    describe 'associate_user' do
      before do
        Spree::Order.stub(:where).with(:number => order.number).and_return([order])
        order.stub(:associate_user_for_pos).with('test-user@pos.com', 'test', 'user', '07123456789').and_return(user)
      end

      def send_request(params = {})
        post :associate_user, params.merge!({:use_route => 'spree'})
      end

      it 'associates user with order' do
        order.should_receive(:associate_user_for_pos).with('test-user@pos.com', 'test', 'user', '07123456789').and_return(user)
        send_request(:number => order.number, :new_email =>'test-user@pos.com', :first_name => 'test', :last_name => 'user', :phone => '07123456789')
      end

      context 'if user added successfully' do
        it 'redirects to action show' do
          send_request(:number => order.number, :new_email =>'test-user@pos.com', :first_name => 'test', :last_name => 'user', :phone => '07123456789')
          response.should redirect_to(:action => :show, :number => order.number)
        end

        it 'sets the flash message' do
          send_request(:number => order.number, :new_email =>'test-user@pos.com', :first_name => 'test', :last_name => 'user', :phone => '07123456789')
          flash[:notice].should eq('Successfully Associated User')
        end
      end

      context 'if user not added' do
        before do
          @error_object = Object.new
          @error_object.stub_chain(:full_messages, :to_sentence).and_return('error_message')
          user.stub(:errors).and_return(@error_object)
        end
        
        it 'redirects to action show' do
          send_request(:number => order.number, :new_email =>'test-user@pos.com', :first_name => 'test', :last_name => 'user', :phone => '07123456789')
          response.should redirect_to(:action => :show, :number => order.number)
        end

        it 'sets the flash message' do
          send_request(:number => order.number, :new_email =>'test-user@pos.com', :first_name => 'test', :last_name => 'user', :phone => '07123456789')
          flash[:error].should eq('Could not add the user:error_message')
        end
      end
    end

    describe 'update_payment' do
      def send_request(params = {})
        post :update_payment, params.merge!({ :use_route => 'spree'})
      end

      before do
        Spree::Order.stub(:where).with(:number => order.number).and_return([order])
        @payment_method = mock_model(Spree::PaymentMethod)
        Spree::PaymentMethod.stub(:where).with(:id => @payment_method.id.to_s).and_return([@payment_method])
        order.stub(:save_payment_for_pos).with(@payment_method.id.to_s, 'Credit Card').and_return(payment)
        order.stub(:complete_via_pos).and_return(true)
      end

      it 'save payment for order' do
        order.should_receive(:save_payment_for_pos).with(@payment_method.id.to_s, 'Credit Card').and_return(payment)
        send_request(:number => order.number, :payment_method_id => @payment_method.id, :card_name => 'Credit Card')
      end

      context 'payment successfully updated' do
        it 'prints the order' do
          controller.should_receive(:print).and_return{ controller.render :nothing => true }
          send_request(:number => order.number, :payment_method_id => @payment_method.id, :card_name => 'Credit Card')
        end
      end

      context 'payment not saved' do
        before do
          @error_object = Object.new
          @error_object.stub_chain(:full_messages, :to_sentence).and_return('error_message')
          payment.stub(:errors).and_return(@error_object)
        end

        it 'redirects to action show' do
          send_request(:number => order.number, :payment_method_id => @payment_method.id, :card_name => 'Credit Card')
          response.should redirect_to(:action => :show, :number => order.number)
        end

        it 'sets the error message' do
          send_request(:number => order.number, :payment_method_id => @payment_method.id, :card_name => 'Credit Card')
          flash[:error].should eq('error_message')
        end

        it 'should not complete order' do
          order.should_not_receive(:complete_via_pos)
          send_request(:number => order.number, :payment_method_id => @payment_method.id, :card_name => 'Credit Card')
        end
      end
    end

    describe 'update_stock_location' do
      def send_request(params = {})
        put :update_stock_location, params.merge!(:use_route => 'spree')
      end

      before do
        Spree::Order.stub(:where).with(:number => order.number).and_return([order])
        @stock_location = mock_model(Spree::StockLocation)
        @stock_location.stub(:address).and_return(address)
        @stock_locations = [@stock_location]
        @stock_locations.stub(:where).with(:id => @stock_location.id.to_s).and_return(@stock_locations)
        Spree::StockLocation.stub_chain(:active, :stores).and_return(@stock_locations)
      
        @shipment = mock_model(Spree::Shipment)
        order.stub(:ship_address=).with(address).and_return(address)
        order.stub(:bill_address=).with(address).and_return(address)
        @shipment.stub(:stock_location=).with(@stock_location).and_return(@stock_location)
        @shipment.stub(:stock_location).and_return(@stock_location)

        order.stub(:shipment).and_return(@shipment)
        order.stub(:save).and_return(true)
        @shipment.stub(:save).and_return(true)
      end

      describe 'updates order addresses and update shipment' do
        it { @stock_location.stub(:address).and_return(address) }
        it { order.stub(:ship_address=).with(address).and_return(address) }
        it { order.stub(:bill_address=).with(address).and_return(address) }
        it { @shipment.stub(:stock_location=).with(@stock_location).and_return(@stock_location) }
        it { @shipment.stub(:stock_location).and_return(@stock_location) }
        it { order.stub(:shipment).and_return(@shipment) }
        it { order.stub(:save).and_return(true) }
        it { @shipment.stub(:save).and_return(true) }
        it { order.should_receive(:save).and_return(true) }

        after { send_request(:number => order.number, :stock_location_id => @stock_location.id) }
      end

      it 'redirects to action show' do
        send_request(:number => order.number, :stock_location_id => @stock_location.id)
        response.should redirect_to(:action => :show, :number => order.number)
      end
    end
  end
end