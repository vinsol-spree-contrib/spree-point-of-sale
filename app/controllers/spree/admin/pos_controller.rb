class Spree::Admin::PosController < Spree::Admin::BaseController
  before_filter :check_valid_order, :except => [:new]
  helper_method :user_stock_locations
  before_filter :load_variant, :only => [:add, :remove]
  before_filter :ensure_pos_shipping_method, :only => [:new]
  before_filter :ensure_payment_method, :only => [:update_payment]

  def new
    @order = spree_current_user.unpaid_pos_orders.first
    @order ? add_error("You have an unpaid/empty order. Please either complete it or update items in the same order.") : init_pos
    redirect_to :action => :show , :number => @order.number
  end

  def find
    init_search

    #using the scope available_at_stock_location which should be defined according to app or removed if not required
    stock_location = user_stock_locations(spree_current_user).first
    @search = Spree::Variant.includes([:product]).available_at_stock_location(stock_location.id).ransack(params[:q])
    @variants = @search.result(:distinct => true).page(params[:page]).per(20)
  end

  def add
    @line_item = add_variant(@variant) if @variant.present?
    flash.notice = @line_item.errors[:base].present? ? 'Adding more than available' : Spree.t('product_added') if @line_item
    redirect_to :action => :show, :number => @order.number 
  end

  def remove
    line_item = @order.contents.remove(@variant, 1, @order.shipment)
    flash.notice = line_item.quantity != 0 ? 'Quantity Updated' : Spree.t('product_removed') 
    redirect_to :action => :show, :number => @order.number
  end

  def update_line_item_quantity
    item = @order.line_items.where(:id => params[:line_item_id]).first
    #TODO error handling
    item.quantity = params[:quantity].to_i
    item.save

    flash.notice = item.errors[:base].present? ? 'Adding more than available.' : 'Quantity Updated'      
    redirect_to :action => :show
  end

  def apply_discount
    if VALID_DISCOUNT_REGEX.match(params[:discount]) && params[:discount].to_f < 100
      @discount = params[:discount].to_f
      item = @order.line_items.where(:id => params[:line_item_id]).first
      item.price = item.variant.price * ( 1.0 - @discount/100.0 )
      item.save
    else
      flash[:notice] = 'Please enter a valid discount'
    end
    redirect_to :action => :show
  end

  def clean_order
    @order.clean!
    flash[:notice] = "Removed all items"
    redirect_to :action => :show, :number => @order.number
  end

  def associate_user
    @user = @order.associate_user_for_pos(params[:email].present? ? params[:email] : params[:new_email])
    if @user.errors.present?
      add_error "Could not add the user:#{@user.errors.full_messages.to_sentence}"
    else
      @order.save!
      flash[:notice] = 'Successfully Associated User'
    end

    redirect_to :action => :show, :number => @order.number
  end

  def update_payment
    @payment_method_id = params[:payment_method_id]
    @payment = @order.save_payment_for_pos(params[:payment_method_id], params[:card_name])
    if @payment.errors.blank?
      print
    else
      add_error @payment.errors.full_messages.to_sentence
      redirect_to :action => :show, :number => @order.number
    end
  end

  def update_stock_location
    @order.shipment.stock_location = user_stock_locations(spree_current_user).where(:id => params[:stock_location_id]).first
    @order.bill_address = @order.ship_address = @order.shipment.stock_location.address
    @order.save
    @order.shipment.save
    redirect_to :action => :show, :number => @order.number
  end

  private 
  
  def ensure_pos_shipping_method
    redirect_to '/', :flash => { :error => 'No shipping method available for POS orders. Please assign one.'} and return unless Spree::ShippingMethod.where(:name => SpreePos::Config[:pos_shipping]).first
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
    load_order
    if @order.paid? || !@order.is_pos?
      flash[:error] = 'This order is already completed. Please use a new one.' if @order.paid?
      flash[:error] = 'This is not a pos order' unless @order.is_pos?
      render :show
    end
  end

  def ensure_payment_method
    if Spree::PaymentMethod.where(:id => params[:payment_method_id]).blank?
      flash[:error] = 'Please select a payment method'
      redirect_to :action => :show, :number => @order.number
    end
  end

  def init_pos
    @order = Spree::Order.new(:state => "complete", :is_pos => true, :completed_at => Time.current, :payment_state => 'balance_due')
    @order.associate_user!(spree_current_user)
    @order.bill_address = @order.ship_address = Spree::StockLocation.active.stores.first.address
    @order.save!
    @order.assign_shipment_for_pos
    @order.save!
    session[:pos_order] = @order.number
  end

  def add_error no
    flash[:error] = "" unless flash[:error]
    flash[:error] << no
  end

  def add_variant var , quant = 1
    # init_pos unless @order 
    line_item = @order.contents.add(var, quant, nil, @order.shipment)
    #TODO Hack to get the inventory to update. There must be a better way, but i'm lost in spree jungle
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