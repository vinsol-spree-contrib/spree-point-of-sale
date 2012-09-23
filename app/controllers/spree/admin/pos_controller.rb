class Spree::Admin::PosController < Spree::Admin::BaseController
  before_filter :get_order , :except => :new
  
  def get_order
    order_number = params[:number]
    @order = Spree::Order.find_by_number(order_number)
    raise "No order found for -#{order_number}-" unless @order
  end
    
  def new
    unless params[:force]
      @order = Spree::Order.last # TODO , this could be per user
    end
    init if @order == nil or not @order.complete?
    redirect_to :action => :show , :number => @order.number
  end

  def export
    unless session[:items]
      show
      return
    end
    missing = []
    session[:items].each do |key , item | 
      missing << item.variant.full_name if item.variant.ean.blank?
    end
    unless missing.empty?
      flash[:error] = "All items must have ean set, missing: #{missing.join(' , ')}"
      redirect_to :action => :show 
      return
    end
    opt = {}
    session[:items].each do |key , item | 
      var = item.variant
      opt[var.ean] = item.quantity
      var.on_hand =  var.on_hand - item.quantity
      var.save!
    end
    init  # reset this pos
    opt[:host] = "" #Spree::Config[:pos_export] 
    opt[:controller] = "pos" 
    opt[:action] = "import" 
    redirect_to opt
  end
  
  def import
    init
    added = 0
    params.each do |id , quant |
      next if id == "action" 
      next if id == "controller" 
      v = Spree::Variant.find_by_ean id
      if v 
        add_variant(v , quant )
        added += 1
      else
        v = Spree::Variant.find_by_sku id
        if v 
          add_variant(v , quant )
          added += 1
        else
          add_error "No product found for EAN #{id}     "
        end
      end
    end
    add_notice "Added #{added} products" if added
    redirect_to :action => :show
  end
  
  def inventory
    if @order.state == "complete"
      flash[:error] = "Order was already completed (printed), please start with a new customer to add inventory"     
      redirect_to :action => :show 
      return
    end
    as = params[:as]
    num = 0 
    prods = @order.line_items.count
    @order.line_items.each do |item |
      variant = item.variant
      num += item.quantity
      if as
        variant.on_hand = item.quantity
      else
        variant.on_hand += item.quantity
      end
      variant.save!
    end
    @order.line_items.clear
    flash.notice = "Total of #{num} items #{as ? 'inventoried': 'added'} for #{prods} products "     
    redirect_to :action => :show 
  end
  
  def add
    if pid = params[:item]
      add_variant Spree::Variant.find pid
      flash.notice = t('product_added')
    end
    redirect_to :action => :show 
  end

  def remove
    if pid = params[:item]
      variant = Spree::Variant.find(pid)
      line_item = @order.line_items.find { |line_item| line_item.variant_id == variant.id }
      line_item.quantity -= 1
      if line_item.quantity == 0
        @order.line_items.delete line_item
      else
        line_item.save
      end
      flash.notice = t('product_removed') 
    end
    redirect_to :action => :show 
  end

  def print
    unless @order.payment_ids.empty?
      @order.payments.first.delete unless @order.payments.first.amount == @order.total
    end
    if @order.payment_ids.empty?
      payment = Spree::Payment.new
      payment.payment_method = Spree::PaymentMethod.find_by_type_and_environment( "Spree::PaymentMethod::Check" , Rails.env)
      payment.amount = @order.total 
      payment.order = @order 
      payment.save!
      payment.capture!
    end
    @order.state = "complete"
    @order.completed_at = Time.now
    @order.create_tax_charge!
    @order.finalize!
    @order.save!
    url = SpreePos::Config[:pos_printing]
    url = url.sub("number" , @order.number.to_s)
    redirect_to url
  end
  
  def index
    redirect_to :action => :new 
  end
  
  def show
    if params[:price] && request.post?
      pid = params[:price].to_i
      item = @order.line_items.find { |line_item| line_item.id == pid }
      item.price = params["price#{pid}"].to_f
      item.save
      @order.reload # must be something cached in there, because it doesnt work without. shame.
      flash.notice = I18n.t("price_changed")
    end
    if params[:quantity_id] && request.post?
      iid = params[:quantity_id].to_i
      item = @order.line_items.find { |line_item| line_item.id == iid }
      #TODO error handling
      item.quantity = params[:quantity].to_i
      item.save
      #TODO Hack to get the inventory to update. There must be a better way, but i'm lost in spree jungle
      item.variant.product.save
      @order.reload # must be something cached in there, because it doesnt work without. shame.
      flash.notice = I18n.t("quantity_changed")      
    end
    if discount = params[:discount]
      if i_id = params[:item]
        item = @order.line_items.find { |line_item| line_item.id.to_s == i_id }
        item_discount( item , discount )
      else
        @order.line_items.each do |item|
          item_discount( item , discount )
        end
      end
      @order.reload # must be something cached in there, because it doesnt work without. shame.
    end
    if sku = params[:sku]
      prods = Spree::Variant.where(:sku => sku ).limit(2)
      if prods.length == 0 and Spree::Variant.instance_methods.include? "ean"
        prods = Spree::Variant.where(:ean => sku ).limit(2)
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
    item.price = item.variant.price * ( 1.0 - discount.to_f/100.0 )
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
    
  private
  
  def add_notice no
    flash[:notice] = "" unless flash[:notice]
    flash[:notice] << no
  end
  def add_error no
    flash[:error] = "" unless flash[:error]
    flash[:error] << no
  end
  
  def init
    @order = Spree::Order.new 
    @order.user = current_user
    @order.bill_address = @order.user.bill_address
    @order.ship_address = @order.user.ship_address
    @order.email = current_user.email
    @order.save!
    method = Spree::ShippingMethod.find_by_name SpreePos::Config[:pos_shipping]
    @order.shipping_method = method || Spree::ShippingMethod.first
    @order.create_shipment!
    session[:pos_order] = @order.number
  end
  def add_variant var , quant = 1
    init unless @order 
    @order.add_variant(var , quant)
    #TODO Hack to get the inventory to update. There must be a better way, but i'm lost in spree jungle
    var.product.save
  end

  private
  
  def init_search
    params[:q] ||= {}
    params[:q][:meta_sort] ||= "product_name asc"
    params[:q][:deleted_at_null] = "1"
    params[:q][:product_deleted_at_null] = "1"
    @search = Spree::Variant.ransack(params[:q])
    @variants = @search.result(:distinct => true).page(params[:page]).per(20)
  end
end

