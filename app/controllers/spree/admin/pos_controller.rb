class Spree::Admin::PosController < Spree::Admin::BaseController
  before_action :load_order, :ensure_pos_order, :ensure_unpaid_order, :except => [:new]
  helper_method :user_stock_locations
  before_action :load_variant, :only => [:add, :remove]
  before_action :ensure_active_store, :ensure_pos_shipping_method
  before_action :ensure_payment_method, :only => [:update_payment]
  before_action :ensure_existing_user, :only => [:associate_user]
  before_action :check_unpaid_pos_order, :only => :new
  before_action :check_discount_request, :only => :apply_discount
  before_action :load_line_item, :only => [:update_line_item_quantity, :apply_discount]
  before_action :clean_and_reload_order, :only => [:update_stock_location]
  
  def new
    init_pos
    redirect_to admin_pos_show_order_path(:number => @order.number)
  end

  def find
    init_search
    #TODO -> create one method for last_shipment in order_model as it is used in verious locations.
    stock_location = @order.shipments.last.stock_location
    @search = Spree::Variant.includes([:product]).available_at_stock_location(stock_location.id).ransack(params[:q])
    @variants = @search.result(:distinct => true).page(params[:page]).per(PRODUCTS_PER_SEARCH_PAGE)
  end

  def add
    @item = add_variant(@variant) if @variant.present?
    flash[:notice] = Spree.t('product_added') if @item.errors.blank?
    flash[:error] = @item.errors.full_messages.to_sentence if @item.errors.present?
    redirect_to admin_pos_show_order_path(:number => @order.number) 
  end

  def remove
    line_item = @order.contents.remove(@variant, 1, @order.shipments.last)
    @order.assign_shipment_for_pos if @order.reload.shipments.blank?
    flash.notice = line_item.quantity.zero? ? Spree.t('product_removed') : 'Quantity Updated' 
    redirect_to admin_pos_show_order_path(:number => @order.number)
  end

  def update_line_item_quantity
    @item.quantity = params[:quantity]
    @item.save

    flash[:notice] = 'Quantity Updated' if @item.errors.blank?
    flash[:error] = @item.errors.full_messages.to_sentence if @item.errors.present?
    redirect_to admin_pos_show_order_path(:number => @order.number)
  end

  def apply_discount
    @item.price = @item.variant.price * ( 1.0 - @discount/100.0 )
    @item.save
    flash[:error] = @item.errors.full_messages.to_sentence if @item.errors.present?
    redirect_to admin_pos_show_order_path(:number => @order.number)
  end

  def clean_order
    @order.clean!
    redirect_to admin_pos_show_order_path(:number => @order.number), :notice => "Removed all items"
  end

  def associate_user
    @user = @order.associate_user_for_pos(params[:email].present? ? params[:email] : params[:new_email])
    if @user.errors.present?
      add_error "Could not add the user:#{@user.errors.full_messages.to_sentence}"
    else
      @order.save!
      flash[:notice] = 'Successfully Associated User'
    end

    redirect_to admin_pos_show_order_path(:number => @order.number)
  end

  def update_payment
    @payment_method_id = params[:payment_method_id]
    @payment = @order.save_payment_for_pos(params[:payment_method_id], params[:card_name])
    if @payment.errors.blank?
      print
    else
      add_error @payment.errors.full_messages.to_sentence
      redirect_to admin_pos_show_order_path(:number => @order.number)
    end
  end

  def update_stock_location
    @shipment = @order.shipments.last
    @shipment.stock_location = user_stock_locations(spree_current_user).where(:id => params[:stock_location_id]).first
    if @shipment.save
      flash[:notice] = "Updated Successfully"
    else
      flash[:error] = @shipment.errors.full_messages.to_sentence
    end
    redirect_to admin_pos_show_order_path(:number => @order.number)
  end

  private 

  def clean_and_reload_order
    @order.clean!
    load_order
  end

  def check_discount_request
    @discount = params[:discount].try(:to_f)
    redirect_to admin_pos_show_order_path(:number => @order.number), :flash => { :error => 'Please enter a valid discount' } unless VALID_DISCOUNT_REGEX.match(params[:discount]) || @discount >= 100
  end

  def ensure_pos_order
    unless @order.is_pos?
      flash[:error] = 'This is not a pos order'
      render :show
    end
  end

  def ensure_unpaid_order
    if @order.paid?
      flash[:error] = 'This order is already completed. Please use a new one.'
      render :show
    end
  end

  def load_line_item
    @item = @order.line_items.where(:id => params[:line_item_id]).first
  end

  def check_unpaid_pos_order
    if spree_current_user.unpaid_pos_orders.present?
      add_error("You have an unpaid/empty order. Please either complete it or update items in the same order.")
      redirect_to admin_pos_show_order_path(:number => spree_current_user.unpaid_pos_orders.first.number)
    end
  end

  def ensure_existing_user 
    invalid_user_message = "No user with email #{params[:email]}" if params[:email].present? && Spree::User.where(:email => params[:email]).blank?
    invalid_user_message = "User Already exists for the email #{params[:new_email]}" if params[:new_email].present? && Spree::User.where(:email => params[:new_email]).present?
    redirect_to admin_pos_show_order_path(:number => @order.number), :flash => { :error => invalid_user_message } if invalid_user_message
  end

  def ensure_pos_shipping_method
    redirect_to '/', :flash => { :error => 'No shipping method available for POS orders. Please assign one.'} and return unless Spree::ShippingMethod.where(:name => SpreePos::Config[:pos_shipping]).first
  end

  def ensure_active_store
    redirect_to '/', :flash => { :error => 'No active store present. Please assign one.'} and return if Spree::StockLocation.stores.active.blank?
  end

  def load_order
    @order = Spree::Order.by_number(params[:number]).includes([{ :line_items => [{ :variant => [:default_price, { :product => [:master] } ] }] } , { :adjustments => :adjustable }] ).first
    raise "No order found for -#{params[:number]}-" unless @order
  end
  
  def load_variant
    @variant = Spree::Variant.where(:id => params[:item]).first
    unless @variant
      flash[:error] = "No variant"
      render :show
    end
  end

  def check_valid_order
    if @order.paid? || !@order.is_pos?
      flash[:error] = 'This order is already completed. Please use a new one.' if @order.paid?
      flash[:error] = 'This is not a pos order' unless @order.is_pos?
      render :show
    end
  end

  def ensure_payment_method
    if Spree::PaymentMethod.where(:id => params[:payment_method_id]).blank?
      flash[:error] = 'Please select a payment method'
      redirect_to admin_pos_show_order_path(:number => @order.number)
    end
  end

  def init_pos
    @order = Spree::Order.new(:state => "complete", :is_pos => true, :completed_at => Time.current, :payment_state => 'balance_due')
    @order.associate_user!(spree_current_user)
    @order.save!
    @order.assign_shipment_for_pos
    @order.save!
    session[:pos_order] = @order.number
  end

  def add_error error_message
    flash[:error] = "" unless flash[:error]
    flash[:error] << error_message
  end

  def add_variant var , quant = 1
    line_item = @order.contents.add(var, quant, nil, @order.shipments.last)
    var.product.save
    line_item
  end

  def user_stock_locations(user)
    # use this code when stock managers implemented
    # @stock_location ||= (user.has_spree_role?('pos_admin') ? Spree::StockLocation.active.stores : user.stock_locations.active.store)
    Spree::StockLocation.active.stores
  end
  
  def init_search
    params[:q] ||= {}
    params[:q].merge!(:meta_sort => "product_name asc", :deleted_at_null => "1", :product_deleted_at_null => "1", :published_at_not_null => "1")
    params[:q][:product_name_cont].try(:strip!)
  end

  def print
    @order.complete_via_pos
    url = SpreePos::Config[:pos_printing].sub("number" , @order.number.to_s)
    redirect_to url
  end
end