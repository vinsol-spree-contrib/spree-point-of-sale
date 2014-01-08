class Spree::Admin::PosController < Spree::Admin::BaseController
  before_filter :check_valid_order, :except => [:new, :print]
  helper_method :user_stock_location
  before_filter :load_variant, :only => [:add, :remove]
  before_filter :ensure_pos_shipping_method, :only => [:new]

  def load_order
    @order = Spree::Order.by_number(params[:number]).first
    raise "No order found for -#{params[:number]}-" unless @order
  end
  
  def load_variant
    @variant = Spree::Variant.where(:id => params[:item]).first
    render :show, :error => "No variant" unless @variant
  end

  def check_valid_order
    load_order
    render :show, :notice => "This order is already completed. Please use a new one.aggain" if @order.paid?
  end
    
  def new
    @order = spree_current_user.orders.where("is_pos = true and payment_state != 'paid' and completed_at is not null").first

    @order ? add_error("You have an upaid/empty order. Please either complete it or update items in the same order.") : init_pos
  
    redirect_to :action => :show , :number => @order.number
  end

  # def export
  #   unless session[:items]
  #     show
  #     return
  #   end
  #   missing = []
  #   session[:items].each do |key , item | 
  #     missing << item.variant.full_name if item.variant.ean.blank?
  #   end
  #   unless missing.empty?
  #     flash[:error] = "All items must have ean set, missing: #{missing.join(' , ')}"
  #     redirect_to :action => :show 
  #     return
  #   end
  #   opt = {}
  #   session[:items].each do |key , item | 
  #     var = item.variant
  #     opt[var.ean] = item.quantity
  #     var.on_hand =  var.on_hand - item.quantity
  #     var.save!
  #   end
  #   init  # reset this pos
  #   opt[:host] = "" #Spree::Config[:pos_export] 
  #   opt[:controller] = "pos" 
  #   opt[:action] = "import" 
  #   redirect_to opt
  # end
  
  # def import
  #   init
  #   added = 0
  #   params.each do |id , quant |
  #     next if id == "action" 
  #     next if id == "controller" 
  #     v = Spree::Variant.find_by_ean id
  #     if v 
  #       add_variant(v , quant )
  #       added += 1
  #     else
  #       v = Spree::Variant.find_by_sku id
  #       if v 
  #         add_variant(v , quant )
  #         added += 1
  #       else
  #         add_error "No product found for EAN #{id}     "
  #       end
  #     end
  #   end
  #   add_notice "Added #{added} products" if added
  #   redirect_to :action => :show
  # end
  
  # def inventory
  #   if @order.state == "complete"
  #     flash[:error] = "Order was already completed (printed), please start with a new customer to add inventory"     
  #     redirect_to :action => :show 
  #     return
  #   end
  #   as = params[:as]
  #   num = 0 
  #   prods = @order.line_items.count
  #   @order.line_items.includes(:variant => :stock_locations).each do |item |
  #     variant = item.variant
  #     num += item.quantity
  #     stock_item = variant.stock_items.select { |stock_item| stock_item.stock_location_id == @order.shipment.stock_location.id }.first
  #     if as
  #       stock_item.adjust_count_on_hand((item.quantity) - stock_item.count_on_hand)
  #     else
  #       stock_item.adjust_count_on_hand(item.quantity)
  #     end
  #     stock_item.save!
  #   end
  #   @order.line_items.clear
  #   flash.notice = "Total of #{num} items #{as ? 'inventoried': 'added'} for #{prods} products "     
  #   redirect_to :action => :show 
  # end
  
  def add
    @variant = Spree::Variant.where(:id => params[:item]).first
    @line_item = add_variant(@variant) if @variant.present?
    flash.notice = @line_item.errors[:base].present? ? 'Adding more than available' : Spree.t('product_added') if @line_item
    redirect_to :action => :show 
  end

  def remove
    line_item = @order.contents.remove(@variant, 1, @order.shipment)
    flash.notice = line_item.quantity != 0 ? 'Quantity Updated' : Spree.t('product_removed') 
    redirect_to :action => :show 
  end

  def print
    @order.complete_via_pos
    url = SpreePos::Config[:pos_printing].sub("number" , @order.number.to_s)
    redirect_to url
  end
  
  def index
    redirect_to :action => :new 
  end

  def update_stock_location
    @order.shipment.stock_location = user_stock_location(@order.user).where(:id => params[:stock_location_id]).first
    @order.bill_address = @order.ship_address = @order.shipment.stock_location.address
    @order.save
    @order.shipment.save
  end

  def update_price

  end

  def show
    @payment_method_id = @order.payments.first.try(:payment_method_id)
    user_stock_location(spree_current_user)

    # if params[:price] && request.post?
    #   pid = params[:price].to_i
    #   item = @order.line_items.find { |line_item| line_item.id == pid }
    #   item.price = params["price#{pid}"].to_f
    #   item.save
    #   @order.reload # must be something cached in there, because it doesnt work without. shame.
    #   flash.notice = Spree.t("price_changed")
    # end
    if params[:line_item_id] && request.post?
      line_item_id = params[:line_item_id].to_i
      item = @order.line_items.find { |line_item| line_item.id == line_item_id }
      #TODO error handling
      item.quantity = params[:quantity].to_i
      item.save
      #TODO Hack to get the inventory to update. There must be a better way, but i'm lost in spree jungle
      item.variant.product.save
      @order.reload # must be something cached in there, because it doesnt work without. shame.
      flash.notice = item.errors[:base].present? ? 'Adding more than available.' : 'Quantity Updated'      
    end
    if params[:discount]
      valid_discount_regex = /^\d*\.?\d+$/
      if valid_discount_regex.match(params[:discount])
        @discount = params[:discount].to_f
        if i_id = params[:item]
          item = @order.line_items.find { |line_item| line_item.id.to_s == i_id }
          item_discount( item , @discount )
        else
          @order.line_items.each do |item|
            item_discount( item , @discount )
          end
        end
        @order.reload # must be something cached in there, because it doesnt work without. shame.
      else
        flash[:notice] = 'Please enter a valid discount'
      end
    end
    if sku = params[:sku]
      prods = Spree::Variant.available_at_stock_location(@stock_location.first.id).where(:sku => sku ).limit(2)
      if prods.length == 0 and Spree::Variant.instance_methods.include? "ean"
        prods = Spree::Variant.available_at_stock_location(@stock_location.first.id).where(:ean => sku ).limit(2)
      end
      if prods.length == 1
        add_variant prods.first
      else
        redirect_to :action => :find , "q[product_name_cont]" => sku
        return
      end
    end
  end
  
  def item_discount item , discount
    if discount < 100
      flash[:notice] = nil
      item.price = item.variant.price * ( 1.0 - discount/100.0 )
    else
      @discount = 0.0
      flash[:notice] = 'Please enter a valid discount'
    end

    item.save!
  end
  
  def find
    init_search
    if params[:index]
      search = params[:q]
      search["name_cont"] = search["variants_including_master_sku_cont"]
      search["variants_including_master_sku_cont"] = nil
      init_search
    end
  end
    
  def clean_order
    @order.clean!
    flash[:notice] = "Removed all items"
    redirect_to :action => :show , :number => @order.number
  end

  def associate_user
    if @user = Spree::User.where(:email => params[:email]).first
      @order.associate_user!(@user)
      add_notice 'Successfully Added'
    else 
      @user = create_user_with_random_password(params[:new_email], params[:first_name], params[:last_name], params[:phone])
      if @user.errors.present?
        add_error "Could not add the user:#{@user.errors.full_messages.to_sentence}"
      else
        @order.associate_user!(@user)
        add_notice 'Successfully Added New User'
      end
    end
    
    redirect_to :action => :show , :number => @order.number
  end

  def save_payment_for_order(order, payment_method_id, card_name = nil)
    order.payments.delete_all
    @payment = order.payments.new(:amount => order.total, :payment_method_id => payment_method_id, :card_name => card_name)
    @payment.save
  end
 
  def update_payment
    if Spree::PaymentMethod.where(:id => params[:payment_method_id]).present?
      #needed to retain payment method selection for redirect to show
      @payment_method_id = params[:payment_method_id]
      if save_payment_for_order(@order, params[:payment_method_id], params[:card_name])
        print
      else
        add_error @payment.errors.full_messages.to_sentence
        redirect_to :action => :show , :number => @order.number
      end
    else
      add_error 'Please select a payment method'
      redirect_to :action => :show , :number => @order.number
    end
  end

  private
  
  def ensure_pos_shipping_method
    redirect_to '/', :flash => { :error => 'No shipping method available for POS orders. Please assign one.'} and return unless Spree::ShippingMethod.where(:name => SpreePos::Config[:pos_shipping]).first
  end

  def create_user_with_random_password(email, fname, lname, phone)
    random_pass = [*('A'..'Z'),*(1..9)].sample(8).join
    Spree::User.create(:email => email, :first_name => fname, :last_name => lname, :phone => phone, :password => random_pass)    
  end

  def add_notice no
    flash[:notice] = "" unless flash[:notice]
    flash[:notice] << no
  end

  def add_error no
    flash[:error] = "" unless flash[:error]
    flash[:error] << no
  end
  
  def init_pos
    @order = Spree::Order.new(:state => "complete", :is_pos => true, :completed_at => Time.now, :payment_state => 'balance_due')
    @order.associate_user!(spree_current_user)
    @order.bill_address = @order.ship_address = Spree::StockLocation.active.stores.first.address
    @order.save!
    @order.assign_shipment_for_pos
    @order.save!
    session[:pos_order] = @order.number
  end

  def add_variant var , quant = 1
    init_pos unless @order 
    @line_item = @order.contents.add(var, quant, nil, @order.shipment)
    #TODO Hack to get the inventory to update. There must be a better way, but i'm lost in spree jungle
    var.product.save
    @line_item
  end

  def user_stock_location(user)
    # use this code when stock managers implemented
    # @stock_location ||= (user.has_spree_role?('pos_admin') ? Spree::StockLocation.active.stores : user.stock_locations.active.store)
    @stock_location = Spree::StockLocation.active.stores
  end
  
  def init_search
    params[:q] ||= {}
    params[:q].merge(:meta_sort => "product_name asc", :deleted_at_null => "1", :product_deleted_at_null => "1", :published_at_not_null => "1")
    params[:q][:product_name_cont].try(:strip!)
    user_stock_location(spree_current_user)

    #using the scope available_at_stock_location which should be defined according to app or removed if not required
    @search = Spree::Variant.available_at_stock_location(@stock_location.first.id).ransack(params[:q])
    @variants = @search.result(:distinct => true).page(params[:page]).per(20)
  end
end